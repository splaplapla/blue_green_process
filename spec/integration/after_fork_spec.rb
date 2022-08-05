# frozen_string_literal: true

RSpec.describe "BlueGreenProcess integration after_fork" do
  let(:file) { Tempfile.new }
  let(:worker_instance) { worker_class.new(file) }
  let(:worker_class) do
    Class.new(BlueGreenProcess::BaseWorker) do
      def initialize(file)
        @file = file
      end

      def work(label)
        BlueGreenProcess.config.logger.debug "#{label}'ll work(#{$PROCESS_ID})"
        @file.write label
        @file.flush
      end
    end
  end

  context "no after_fork" do
    it "workerからファイルへ書き込みをすること" do
      process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 2)

      process.work # blue
      process.work # green
      process.work # blue
      process.shutdown

      file.rewind
      result = file.read
      expect(result).to eq(
        ["blue" * 2,
         "green" * 2,
         "blue"  * 2].join
      )
      expect(BlueGreenProcess.performance.process_switching_time_before_work).to be_a(Numeric)
    end

    context "has after_fork" do
      it "workerからファイルへ書き込みをすること" do
        BlueGreenProcess.configure do |config|
          config.after_fork = -> { puts "hello fork!!!!!!!" }
        end

        process = BlueGreenProcess.new(worker_instance: worker_instance, max_work: 2)

        process.work # blue
        process.work # green
        process.work # blue
        process.shutdown

        file.rewind
        result = file.read
        expect(result).to eq(
          ["blue" * 2,
           "green" * 2,
           "blue"  * 2].join
        )
      end
    end
  end
end
