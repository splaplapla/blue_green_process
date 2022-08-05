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

  describe "integration" do
    before do
      BlueGreenProcess.config.logger = Logger.new($stdout)
    end
    let(:file) { Tempfile.new }
    let(:worker_instance) { worker_class.new(file) }

    context "work内で例外が起きるとき" do
      let(:worker_class) do
        Class.new(BlueGreenProcess::BaseWorker) do
          def initialize(file)
            @file = file
          end

          def work(_label)
            raise RuntimeError
          end
        end
      end

      it "blue greenなプロセスが停止すること" do
      end

      it "例外がmasterプロセスに伝播すること" do
      end
    end
  end
end
