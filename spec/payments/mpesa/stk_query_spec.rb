require "spec_helper"

RSpec.describe Payments::Mpesa::StkQuery do
  include_context "Mpesa config"

  let(:checkout_request_id) { "ws_CO_123456789" }

  context "successful query" do
    subject do
      stub_request(:post, %r{/stkpushquery}).to_return(
        status: 200,
        body: {
          "ResultCode" => "0",
          "ResultDesc" => "The service request is processed successfully.",
          "CheckoutRequestID" => checkout_request_id
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(checkout_request_id:)
    end

    it "returns a success response" do
      expect(subject).to be_success
      expect(subject.data["ResultDesc"]).to eq("The service request is processed successfully.")
    end
  end

  context "error response" do
    subject do
      stub_request(:post, %r{/stkpushquery}).to_return(
        status: 400,
        body: {
          "errorCode" => "400.001.1001",
          "errorMessage" => "Invalid Request"
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(checkout_request_id:)
    end

    it "marks response as error" do
      expect(subject).to be_error
      expect(subject.message).to eq("Invalid Request")
    end
  end
end
