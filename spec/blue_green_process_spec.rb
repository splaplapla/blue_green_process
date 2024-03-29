# frozen_string_literal: true

RSpec.describe BlueGreenProcess do
  it "has a version number" do
    expect(BlueGreenProcess::VERSION).not_to be nil
  end

  describe ".config" do
    describe ".logger" do
      context "loggerをセットしないとき" do
        it do
          BlueGreenProcess.config.logger.info "hoge"
        end
      end

      context "loggerをセットしたとき" do
        let(:file) { Tempfile.new }
        let(:logger) { Logger.new(file) }

        subject { BlueGreenProcess.config.logger.info "hogehoge" }

        before do
          BlueGreenProcess.config.logger = logger
        end

        it do
          subject
          file.rewind
          expect(file.read).to include("hogehoge")
        end
      end
    end
  end

  describe ".configure" do
    it do
      object = double(:object)
      expect(object).to receive(:run)
      described_class.configure do |config|
        config.after_fork = -> { object.run }
      end

      described_class.config.after_fork.call
    end
  end

  describe ".terminate_workers_immediately" do
    let(:worker_instance) { worker_class.new }
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def work(label)
          puts "work #{label}"
        end
      end
    end

    it "workerプロセスを終了すること" do
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 3)
      process.work
      BlueGreenProcess.terminate_workers_immediately
      expect(Process.waitall).to eq([])
      expect(File.exist?(BlueGreenProcess::PID_PATH)).to eq(false)
    end
  end
end
