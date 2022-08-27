# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration extend run on single_process" do
  let(:worker_instance) { worker_class.new }

  context "when extend_run_on_this_process が常にtrueのとき" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          BlueGreenProcess::SharedVariable.instance.data["count"] += 1
          BlueGreenProcess::SharedVariable.instance.extend_run_on_this_process = true
          BlueGreenProcess::SharedVariable.instance.data["count_display"] = "#{label}:#{BlueGreenProcess::SharedVariable.instance.data['count']}"
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = [:count, :count_display]
      end
    end

    it do
      BlueGreenProcess::SharedVariable.instance.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq(nil)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("blue:3")
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("blue:6")
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("blue:9")
    ensure
      process&.shutdown
    end
  end

  context "when extend_run_on_this_process が常にfalseのとき" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          BlueGreenProcess::SharedVariable.instance.data["count"] += 1
          BlueGreenProcess::SharedVariable.instance.extend_run_on_this_process = false
          BlueGreenProcess::SharedVariable.instance.data["count_display"] = "#{label}:#{BlueGreenProcess::SharedVariable.instance.data['count']}"
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = [:count, :count_display]
      end
    end

    it do
      BlueGreenProcess::SharedVariable.instance.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq(nil)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("blue:3")
      process.work # green
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("green:6")
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("blue:9")
    ensure
      process&.shutdown
    end
  end

  context "when extend_run_on_this_process が途中で反転するとき" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          BlueGreenProcess::SharedVariable.instance.data["count"] += 1
          if BlueGreenProcess::SharedVariable.instance.data["count"] == 6
            BlueGreenProcess::SharedVariable.instance.extend_run_on_this_process = true
          end
          BlueGreenProcess::SharedVariable.instance.data["count_display"] = "#{label}:#{BlueGreenProcess::SharedVariable.instance.data['count']}"
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = [:count, :count_display]
      end
    end

    it do
      BlueGreenProcess::SharedVariable.instance.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq(nil)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("blue:3")
      process.work # green
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("green:6")
      process.work # green
      expect(BlueGreenProcess::SharedVariable.instance.data["count_display"]).to eq("green:9")
    ensure
      process&.shutdown
    end
  end
end
