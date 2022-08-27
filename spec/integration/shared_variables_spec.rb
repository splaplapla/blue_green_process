# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration shared_variables" do
  let(:worker_instance) { worker_class.new }

  describe "shared_variables" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          BlueGreenProcess::SharedVariable.data["count"] += 1
          puts "#{label}'s data['count'] is #{BlueGreenProcess::SharedVariable.data["count"]}"
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = [:count]
      end
    end

    it do
      BlueGreenProcess::SharedVariable.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.data["count"]).to eq(0)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.data["count"]).to eq(3)
      process.work # green
      expect(BlueGreenProcess::SharedVariable.data["count"]).to eq(6)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.data["count"]).to eq(9)
      process.shutdown
    end
  end
end
