# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration extend run on single_process" do
  let(:worker_instance) { worker_class.new }

  context "when extend_run_on_this_process が常にtrueのとき" do
    describe "GC.startを実行しない" do
      let(:worker_class) do
        Class.new(BlueGreenProcess::BaseWorker) do
          def work(_label)
            BlueGreenProcess::SharedVariable.data["gc_count"] = GC.count
            BlueGreenProcess::SharedVariable.extend_run_on_this_process = true
          end
        end
      end

      before do
        BlueGreenProcess.configure do |config|
          config.shared_variables = %i[gc_count]
        end
      end

      it "gc countが増えないこと" do
        process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
        expect(BlueGreenProcess::SharedVariable.data["gc_count"]).to be_nil
        process.work
        expect { process.work }.not_to change { BlueGreenProcess::SharedVariable.data["gc_count"] }
        expect { process.work }.not_to change { BlueGreenProcess::SharedVariable.data["gc_count"] }
        expect { process.work }.not_to change { BlueGreenProcess::SharedVariable.data["gc_count"] }
      ensure
        process&.shutdown
      end
    end

    describe "値の共有" do
      let(:worker_class) do
        Class.new(BlueGreenProcess::BaseWorker) do
          def work(label)
            BlueGreenProcess::SharedVariable.data["count"] += 1
            BlueGreenProcess::SharedVariable.extend_run_on_this_process = true
            BlueGreenProcess::SharedVariable.data["count_display"] =
              "#{label}:#{BlueGreenProcess::SharedVariable.data["count"]}"
          end
        end
      end

      before do
        BlueGreenProcess.configure do |config|
          config.shared_variables = %i[count count_display]
        end
      end

      it do
      end

      it do
        BlueGreenProcess::SharedVariable.data["count"] = 0
        process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
        expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq(nil)
        process.work # blue
        expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("blue:3")
        process.work # blue
        expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("blue:6")
        process.work # blue
        expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("blue:9")
      ensure
        process&.shutdown
      end
    end
  end

  context "when extend_run_on_this_process が常にfalseのとき" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          BlueGreenProcess::SharedVariable.data["count"] += 1
          BlueGreenProcess::SharedVariable.extend_run_on_this_process = false
          BlueGreenProcess::SharedVariable.data["count_display"] =
            "#{label}:#{BlueGreenProcess::SharedVariable.data["count"]}"
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = %i[count count_display]
      end
    end

    it do
      BlueGreenProcess::SharedVariable.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq(nil)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("blue:3")
      process.work # green
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("green:6")
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("blue:9")
    ensure
      process&.shutdown
    end
  end

  context "when extend_run_on_this_process が途中で反転するとき" do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          BlueGreenProcess::SharedVariable.data["count"] += 1
          BlueGreenProcess::SharedVariable.extend_run_on_this_process = true if BlueGreenProcess::SharedVariable.data["count"] == 6
          BlueGreenProcess::SharedVariable.data["count_display"] =
            "#{label}:#{BlueGreenProcess::SharedVariable.data["count"]}"
        end
      end
    end

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = %i[count count_display]
      end
    end

    it do
      BlueGreenProcess::SharedVariable.data["count"] = 0
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq(nil)
      process.work # blue
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("blue:3")
      process.work # green
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("green:6")
      process.work # green
      expect(BlueGreenProcess::SharedVariable.data["count_display"]).to eq("green:9")
    ensure
      process&.shutdown
    end
  end
end
