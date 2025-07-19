RSpec.describe Paytree::Utils::ErrorHandling do
  let(:test_class) do
    Class.new do
      include Paytree::Utils::ErrorHandling
    end
  end

  let(:instance) { test_class.new }
  let(:mock_config) { double("config") }
  let(:mock_logger) { double("logger", error: nil, warn: nil) }

  before do
    allow(Paytree).to receive(:[]).with(:mpesa).and_return(mock_config)
    allow(mock_config).to receive(:respond_to?).with(:logger).and_return(true)
    allow(mock_config).to receive(:logger).and_return(mock_logger)
  end

  describe "#emit_error" do
    let(:test_error) { StandardError.new("Test error") }

    it "logs the error" do
      expect(mock_logger).to receive(:error)

      expect do
        instance.send(:emit_error, test_error, "stk_push")
      end.not_to raise_error
    end
  end
end
