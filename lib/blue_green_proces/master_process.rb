class BlueOrGreenProcess::ParentProcess
  def initialize(worker_class:: , max_work: )
    blue = fork_process(label: :blue, worker_class: worker_class)
    green = fork_process(label: :green, worker_class: worker_class)

    @stage_state = true
    @stage = {
      true => blue.be_active,
      false => green.be_inactive,
    }
    @processes = @stage.values
    @max_work = max_work
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
      process.wpipe.puts(PROCESS_COMMAND_DIE)
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

