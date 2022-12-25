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

    # @return [Array<Integer>]
    # 削除予定
    def pids
      @processes.map(&:pid)
    end

    # @return [Array<Integer>]
    def worker_pids
      @processes.map(&:pid)
    end

    # @return [BlueGreenProcess::WorkerProcess]
    def fork_process(label:, worker_instance:)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = fork do
        BlueGreenProcess.config.after_fork.call
        ::GC.disable

        parent_write.close
        parent_read.close
        process_status = :inactive
        handle_signal(pipes: [child_read, child_write])

        loop do
          next unless (data = child_read.gets)

          json = JSON.parse(data.strip)
          command = json["c"]
          case command
          when BlueGreenProcess::PROCESS_COMMAND_DIE, nil, ""
            BlueGreenProcess.logger.debug "[BLUE_GREEN_PROCESS] #{label} will die(#{$PROCESS_ID})"
            exit 0
          when BlueGreenProcess::PROCESS_COMMAND_BE_ACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_ACTIVE
            BlueGreenProcess::SharedVariable.instance.restore(json["data"])
            BlueGreenProcess.logger.debug "[BLUE_GREEN_PROCESS] #{label} has become active(#{$PROCESS_ID})"
            child_write.puts({ c: BlueGreenProcess::RESPONSE_OK }.to_json)
          when BlueGreenProcess::PROCESS_COMMAND_BE_INACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_INACTIVE
            BlueGreenProcess.logger.debug "[BLUE_GREEN_PROCESS] #{label} has become inactive(#{$PROCESS_ID})"
            child_write.puts({ c: BlueGreenProcess::RESPONSE_OK,
                               data: BlueGreenProcess::SharedVariable.data }.to_json)
            ::GC.start unless BlueGreenProcess::SharedVariable.extend_run_on_this_process
          when BlueGreenProcess::PROCESS_COMMAND_WORK
            if process_status == BlueGreenProcess::PROCESS_STATUS_INACTIVE
              warn "Should not be able to run in this status"
            end

            begin
              worker_instance.work(*label)
              child_write.puts({ c: BlueGreenProcess::RESPONSE_OK }.to_json)
            rescue StandardError => e
              child_write.puts({ c: BlueGreenProcess::RESPONSE_ERROR, err_class: e.class.name,
                                 err_message: e.message }.to_json)
            end
          else
            child_write.puts "NG"
            puts "unknown. from #{label}(#{$PROCESS_ID})"
            exit 1
          end
        rescue IOError # NOTE: シグナル経由でpipeが破棄された時にこれが発生する
          exit 127
        end

        exit 0
      end

      child_write.close
      child_read.close

      BlueGreenProcess::WorkerProcess.new(pid, label, parent_read, parent_write)
    end

    # @return [void]
    def work
      active_process do |process|
        @max_work.times do
          process.work
        end
      end
    rescue BlueGreenProcess::ErrorWrapper => e
      shutdown
      BlueGreenProcess.logger.error "[BLUE_GREEN_PROCESS] #{e.error_class}: #{e.message}"
      raise eval(e.error_class), e.message
    end

    # @return [void]
    def shutdown
      @processes.each(&:shutdown)
      Process.waitall
    end

    private

    # @return [void]
    def active_process
      active_process = nil
      @stage[!@stage_state].be_inactive
      process_switching_time = Benchmark.realtime do
        active_process = @stage[@stage_state].be_active
      end
      BlueGreenProcess.performance.process_switching_time_before_work = process_switching_time

      yield(active_process)

      active_process.be_inactive
      if BlueGreenProcess::SharedVariable.extend_run_on_this_process
        BlueGreenProcess::SharedVariable.extend_run_on_this_process = false
        active_process.be_active
      else
        @stage_state = !@stage_state
      end

      true
    end

    # @return [void]
    # シグナルを受け取ってpipeをcloseする
    def handle_signal(pipes:)
      Thread.new do
        self_read, self_write = IO.pipe
        %w[INT TERM].each do |sig|
          trap sig do
            self_write.puts(sig)
          end
        rescue ArgumentError
          warn("Signal #{sig} not supported")
        end

        begin
          while (readable_io = IO.select([self_read]))
            signal = readable_io.first[0].gets.strip
            case signal
            when "TERM"
              raise Interrupt
            when "INT"
              BlueGreenProcess.logger.warn "[BLUE_GREEN_PROCESS][#{$$}] INTシグナルは無視します"
            end
          end
        rescue Interrupt
          pipes.each(&:close)
        end
      end
    end
  end
end
