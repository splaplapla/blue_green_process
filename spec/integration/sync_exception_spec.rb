# frozen_string_literal: true

RSpec.describe "BlueGreenProcess sync exception" do
  let(:worker_instance) { worker_class.new }

  describe "shared_variables" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          puts "#{label}'s data['count'] is #{BlueGreenProcess::SharedVariable.instance.data["count"]}"
        end
      end
    end

    it do
      BlueGreenProcess::SharedVariable.instance.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.instance.data["count"]).to eq(0)
      process.work # blue
      process.work # green
      process.shutdown
    end
  end
end

