# frozen_string_literal: true

RSpec.describe BlueGreenProcess::SharedVariable do
  describe '#restore' do
    let(:hash) do
      { 'foo' => 1,
        'current_layer' => 'up',
        'doing_macro' => true,
      }
    end

    subject { BlueGreenProcess::SharedVariable.instance.restore(hash) }

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = [:current_layer, 'doing_macro']
      end
      BlueGreenProcess::SharedVariable.instance.data = nil
    end

    it do
      expect { subject }.to change { BlueGreenProcess::SharedVariable.instance.data }.from({}).to({"current_layer"=>"up", "doing_macro"=>true})
    end
  end

  describe '#dump' do
    subject { BlueGreenProcess::SharedVariable.instance.dump }

    before do
      BlueGreenProcess.configure do |config|
        config.shared_variables = [:current_layer, 'doing_macro']
      end
      BlueGreenProcess::SharedVariable.instance.data = {
        'foo' => 1,
        'current_layer' => 'up',
        'doing_macro' => true,
      }
    end

    it { expect(subject).to eq({"current_layer"=>"up", "doing_macro"=>true}) }
  end
end
