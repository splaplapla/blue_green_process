# frozen_string_literal: true

RSpec.describe BlueGreenProcess do
  it "has a version number" do
    expect(BlueGreenProcess::VERSION).not_to be nil
  end

  describe 'integration' do
    let(:worker_class) do
      Class.new(BlueGreenProcess::BaseWorker) do
        def initialize(file)
          @file = file
        end

        def work(label)
          @file.write label
          # puts "value: #{label}, size: #{@file.size}, path: #{@file.path}"
        end
      end
    end

    it 'workerからファイルへ書き込みをすること' do
      file = Tempfile.new
      instance = worker_class.new(file)
      process = BlueGreenProcess.new(
        worker_instance: instance,
        max_work: 3,
      )

      process.work # blue
      process.work # green
      process.work # blue

      file.rewind
      result = file.read
      expect(result).to eq(['blue'*3, 'green'*3, 'blue'*3].join)
    end
  end
end
