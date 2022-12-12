# frozen_string_literal: true

RSpec.describe "Signal Handle" do
  let(:worker_class) do
    Class.new(BlueGreenProcess::BaseWorker) do
      def work(_label)
        sleep(0.1)
      end
    end
  end

  it "エラートレースが出ないこと" do
    master_process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 100)
    Thread.new do
      master_process.work
    end
    master_process.worker_pids.each do |pid|
      Process.kill("TERM", pid)
    end

    sleep(0.2)
    result = Process.waitall
    pp result
    expect(result.size).to eq(2)
  end
end
