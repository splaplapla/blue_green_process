# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration sync exception" do
  before do
    Process.waitall
  end

  context 'thorw RuntimeError' do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          if label == :green
            raise RuntimeError, "これはエラーです"
          end
        end
      end
    end

    it "例外がmasterプロセスに伝播すること" do
      process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 3)
      process.work # blue
      expect { process.work }.to raise_error(RuntimeError, "これはエラーです") # green
      children = Process.waitall
      expect(children.map(&:last).map(&:exited?)).to eq([true, true])
    end
  end

  context 'thorw Errno::ESHUTDOWN' do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          if label == :green
            raise Errno::ESHUTDOWN
          end
        end
      end
    end

    it "例外がmasterプロセスに伝播すること" do
      process = BlueGreenProcess.new(worker_instance: worker_class.new, max_work: 3)
      process.work # blue
      expect { process.work }.to raise_error(Errno::ESHUTDOWN) # green
      children = Process.waitall
      expect(children.map(&:last).map(&:exited?)).to eq([true, true])
    end
  end
end
