require "spec_helper"

RSpec.describe Paytree::Response do
  let(:response) do
    described_class.new(
      provider: :mpesa,
      operation: :stk_push,
      status: :success,
      message: "Request accepted",
      code: "0",
      data: {checkout_request_id: "abc123"},
      raw_response: double("Faraday::Response", status: 200)
    )
  end

  it "returns success? as true when status is :success" do
    expect(response.success?).to be true
  end

  it "returns error? as false when status is :success" do
    expect(response.error?).to be false
  end

  it "serializes to a hash correctly" do
    expect(response.to_h).to eq({
      provider: :mpesa,
      operation: :stk_push,
      status: :success,
      message: "Request accepted",
      code: "0",
      data: {checkout_request_id: "abc123"}
    })
  end

  it "exposes raw_response for debugging or inspection" do
    expect(response.raw_response.status).to eq 200
  end

  describe "#retryable?" do
    let(:config) { double("Mpesa Config") }

    before do
      allow(Paytree).to receive(:[]).with(:mpesa).and_return(config)
    end

    context "when response is successful" do
      it "returns false" do
        expect(response.retryable?).to be false
      end
    end

    context "when response is an error" do
      let(:error_response) do
        described_class.new(
          provider: :mpesa,
          operation: :stk_push,
          status: :error,
          message: "Rate limit exceeded",
          code: "429.001.01",
          data: {},
          raw_response: double("Faraday::Response", status: 429)
        )
      end

      context "when error code is in retryable_errors list" do
        before do
          allow(config).to receive(:respond_to?).with(:retryable_errors).and_return(true)
          allow(config).to receive(:retryable_errors).and_return(["429.001.01", "500.001.02"])
        end

        it "returns true" do
          expect(error_response.retryable?).to be true
        end
      end

      context "when error code is not in retryable_errors list" do
        before do
          allow(config).to receive(:respond_to?).with(:retryable_errors).and_return(true)
          allow(config).to receive(:retryable_errors).and_return(["500.001.02"])
        end

        it "returns false" do
          expect(error_response.retryable?).to be false
        end
      end

      context "when config doesn't support retryable_errors" do
        before do
          allow(config).to receive(:respond_to?).with(:retryable_errors).and_return(false)
        end

        it "returns false" do
          expect(error_response.retryable?).to be false
        end
      end

      context "when error has no code" do
        let(:error_without_code) do
          described_class.new(
            provider: :mpesa,
            operation: :stk_push,
            status: :error,
            message: "Network error",
            code: nil,
            data: {},
            raw_response: double("Faraday::Response", status: 500)
          )
        end

        it "returns false" do
          expect(error_without_code.retryable?).to be false
        end
      end
    end
  end
end
