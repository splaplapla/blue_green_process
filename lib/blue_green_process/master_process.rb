# frozen_string_literal: true

module BlueGreenProcess
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

    def fork_process(label:, worker_instance:)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = fork do
        BlueGreenProcess.config.after_fork.call

        parent_write.close
        parent_read.close
        process_status = :inactive

        loop do
          data = child_read.gets&.strip
          case data
          when BlueGreenProcess::PROCESS_COMMAND_DIE, nil, ""
            BlueGreenProcess.config.logger.debug "#{label}'ll die(#{$PROCESS_ID})"
            exit 0
          when BlueGreenProcess::PROCESS_COMMAND_BE_ACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_ACTIVE
            BlueGreenProcess.config.logger.debug "#{label}'ll be active(#{$PROCESS_ID})"
            child_write.puts BlueGreenProcess::PROCESS_RESPONSE
            ::GC.disable
          when BlueGreenProcess::PROCESS_COMMAND_BE_INACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_INACTIVE
            BlueGreenProcess.config.logger.debug "#{label}'ll be inactive(#{$PROCESS_ID})"
            child_write.puts BlueGreenProcess::PROCESS_RESPONSE
            ::GC.start
          when BlueGreenProcess::PROCESS_COMMAND_WORK
            if process_status == BlueGreenProcess::PROCESS_STATUS_INACTIVE
              warn "Should not be able to run in this status"
            end
            # too verbose
            # BlueGreenProcess.config.logger.debug "#{label}'ll work(#{$PROCESS_ID})"
            worker_instance.work(*label)
            child_write.puts BlueGreenProcess::PROCESS_RESPONSE
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

      true
    end

    def shutdown
      @processes.each(&:shutdown)
    end

    private

    def active_process
      active_process = @stage[@stage_state].be_active
      @stage[!@stage_state].be_inactive
      yield(active_process)
      @stage_state = !@stage_state
    end
  end
end
