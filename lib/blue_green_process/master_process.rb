# frozen_string_literal: true

module BlueGreenProcess
  class MasterProcess
    def initialize(worker_class:, max_work:)
      blue = fork_process(label: :blue, worker_class: worker_class)
      green = fork_process(label: :green, worker_class: worker_class)

      @stage_state = true
      @stage = {
        true => blue.be_active,
        false => green.be_inactive
      }
      @processes = @stage.values
      @max_work = max_work
    end


    def fork_process(label:, worker_class:)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe
      worker_instance = worker_class.new

      pid = fork do
        parent_write.close
        parent_read.close
        process_status = :inactive

        loop do
          data = child_read.gets&.strip
          case data
          when BlueGreenProcess::PROCESS_COMMAND_DIE, nil, ""
            BlueGreenProcess.debug_log "#{label}'ll die(#{$PROCESS_ID})"
            break
          when BlueGreenProcess::PROCESS_COMMAND_BE_ACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_ACTIVE
            BlueGreenProcess.debug_log "#{label}'ll be active(#{$PROCESS_ID})"
            child_write.puts BlueGreenProcess::PROCESS_RESPONSE
            ::GC.disable
          when BlueGreenProcess::PROCESS_COMMAND_BE_INACTIVE
            process_status = BlueGreenProcess::PROCESS_STATUS_INACTIVE
            BlueGreenProcess.debug_log "#{label}'ll be inactive(#{$PROCESS_ID})"
            child_write.puts BlueGreenProcess::PROCESS_RESPONSE
            ::GC.enable
            ::GC.start
          when BlueGreenProcess::PROCESS_COMMAND_WORK
            warn "Should not be able to run in this status" if process_status == BlueGreenProcess::PROCESS_STATUS_INACTIVE

            BlueGreenProcess.debug_log "#{label}'ll work(#{$PROCESS_ID})"
            worker_instance.work
            child_write.puts BlueGreenProcess::PROCESS_RESPONSE
          else
            child_write.puts "NG"
            BlueGreenProcess.debug_log "unknown. from #{label}(#{$PROCESS_ID})"
          end
        end
      end

      child_write.close
      child_read.close

      BlueGreenProcess::ChildProcess.new(pid, label, parent_read, parent_write)
    end

    def work
      active_process do |process|
        @max_work.times do
          process.work
        end
      end
    end

    def shutdown
      @processes.each do |process|
        process.wpipe.puts(BlueGreenProcess::PROCESS_COMMAND_DIE)
      end
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
