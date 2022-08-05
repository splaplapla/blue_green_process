# frozen_string_literal: true

module BlueGreenProcess
  class ErrorWrapper < StandardError
    attr_accessor :error_class, :message

    def initialize(error_class, error_message)
      self.error_class = error_class
      self.message = error_message
    end
  end

  class MasterProcess
    def initialize(worker_instance:, max_work:)
      blue = fork_process(label: :blue, worker_instance: worker_instance)
      green = fork_process(label: :green, worker_instance: worker_instance)

      @stage_state = true
      @stage = {
        true => blue.be_active,
        false => green.be_inactive
      }
      @processes = @stage.values
      @max_work = max_work
    end

    def pids
      @processes.map(&:pid)
    end

    def fork_process(label:, worker_instance:)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = fork do
        BlueGreenProcess.config.after_fork.call
        ::GC.disable

        parent_write.close
        parent_read.close
        process_status = :inactive

        loop do
          data = child_read.gets&.strip
          json = JSON.parse(data)
          command = json["c"]
          case command
          when BlueGreenProcess::PROCESS_COMMAND_DIE, nil, ""
            BlueGreenProcess.config.logger.debug "#{label}'ll die(#{$PROCESS_ID})"
            exit 0
          when BlueGreenProcess::PROCESS_COMMAND_BE_ACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_ACTIVE
            BlueGreenProcess::SharedVariable.instance.restore(json["data"])
            BlueGreenProcess.config.logger.debug "#{label}'ll be active(#{$PROCESS_ID})"
            child_write.puts({ c: BlueGreenProcess::RESPONSE_OK }.to_json)
          when BlueGreenProcess::PROCESS_COMMAND_BE_INACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_INACTIVE
            BlueGreenProcess.config.logger.debug "#{label}'ll be inactive(#{$PROCESS_ID})"
            child_write.puts({ c: BlueGreenProcess::RESPONSE_OK,
                               data: BlueGreenProcess::SharedVariable.instance.data }.to_json)
            ::GC.start
          when BlueGreenProcess::PROCESS_COMMAND_WORK
            if process_status == BlueGreenProcess::PROCESS_STATUS_INACTIVE
              warn "Should not be able to run in this status"
            end

            begin
              worker_instance.work(*label)
              child_write.puts({ c: BlueGreenProcess::RESPONSE_OK }.to_json)
            rescue => e
              child_write.puts({ c: BlueGreenProcess::RESPONSE_ERROR, err_class: e.class.name, err_message: e.message }.to_json)
            end
          else
            child_write.puts "NG"
            puts "unknown. from #{label}(#{$PROCESS_ID})"
            exit 1
          end
        end

        exit 0
      end

      child_write.close
      child_read.close

      BlueGreenProcess::WorkerProcess.new(pid, label, parent_read, parent_write)
    end

    def work
      active_process do |process|
        @max_work.times do
          process.work
        end
      end
    rescue BlueGreenProcess::ErrorWrapper => e
      shutdown
      BlueGreenProcess.config.logger.error "#{e.error_class}: #{e.message}"
      raise eval(e.error_class), e.message
    end

    def shutdown
      @processes.each(&:shutdown)
      Process.waitall
    end

    private

    def active_process
      active_process = nil
      @stage[!@stage_state].be_inactive
      process_switching_time = Benchmark.realtime do
        active_process = @stage[@stage_state].be_active
      end
      BlueGreenProcess.performance.process_switching_time_before_work = process_switching_time

      result = yield(active_process)
      active_process.be_inactive
      @stage_state = !@stage_state
      result
    end
  end
end
