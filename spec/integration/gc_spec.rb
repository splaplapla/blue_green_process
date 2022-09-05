# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration gc start" do
  let(:worker_instance) { worker_class.new }

  describe "workをするごとにGC.startを実行する" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(_label)
          BlueGreenProcess::SharedVariable.data["gc_count"] += GC.count
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = %i[gc_count]
      end
    end

    it "gc countが増えること" do
      BlueGreenProcess::SharedVariable.data["gc_count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      process.work
      expect { process.work }.to change { BlueGreenProcess::SharedVariable.data["gc_count"] }
      process.work
      expect { process.work }.to change { BlueGreenProcess::SharedVariable.data["gc_count"] }
      process.work
      expect { process.work }.to change { BlueGreenProcess::SharedVariable.data["gc_count"] }
    ensure
      process&.shutdown
    end
  end
end
