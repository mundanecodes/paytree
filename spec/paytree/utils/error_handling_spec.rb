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

  describe "#with_error_handling" do
    context "when Net::OpenTimeout occurs" do
      it "raises MpesaResponseError with timeout.connection code" do
        expect do
          instance.with_error_handling(context: "b2c") do
            raise Net::OpenTimeout, "Failed to open TCP connection"
          end
        end.to raise_error(Paytree::Errors::MpesaResponseError) do |error|
          expect(error.code).to eq("timeout.connection")
          expect(error.message).to include("Timeout in b2c")
        end
      end
    end

    context "when Net::ReadTimeout occurs" do
      it "raises MpesaResponseError with timeout.read code" do
        expect do
          instance.with_error_handling(context: "b2c") do
            raise Net::ReadTimeout, "Net::ReadTimeout"
          end
        end.to raise_error(Paytree::Errors::MpesaResponseError) do |error|
          expect(error.code).to eq("timeout.read")
          expect(error.message).to include("Timeout in b2c")
        end
      end
    end

    context "when Faraday::TimeoutError occurs" do
      it "raises MpesaResponseError with timeout.request code" do
        expect do
          instance.with_error_handling(context: "b2c") do
            raise Faraday::TimeoutError, "Request timeout"
          end
        end.to raise_error(Paytree::Errors::MpesaResponseError) do |error|
          expect(error.code).to eq("timeout.request")
          expect(error.message).to include("Timeout in b2c")
        end
      end
    end
  end
end
