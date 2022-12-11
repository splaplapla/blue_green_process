# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration sync exception" do
  before do
    Process.waitall
  end

  context "throw RuntimeError" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          raise "これはエラーです" if label == :green
        end
      end
    end

    it "例外がmasterプロセスに伝播すること" do
      process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 3)
      process.work # blue
      expect { process.work }.to raise_error(RuntimeError, "これはエラーです") # green
      expect(Process.waitall).to eq([])
    end
  end

  context "thorw Errno::ESHUTDOWN" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          raise Errno::ESHUTDOWN if label == :green
        end
      end
    end

    it "例外がmasterプロセスに伝播すること" do
      process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 3)
      process.work # blue
      expect { process.work }.to raise_error(Errno::ESHUTDOWN) # green
      expect(Process.waitall).to eq([])
    end
  end
end
