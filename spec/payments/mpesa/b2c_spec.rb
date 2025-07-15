require "spec_helper"

RSpec.describe Payments::Mpesa::B2C do
  include_context "Mpesa config"

  let(:phone_number) { "254712345678" }

  let(:success_body) do
    {
      "ConversationID" => "AG_20210727_00006c4d8f3e5f29f2d1",
      "OriginatorConversationID" => "1234567890",
      "ResponseCode" => "0",
      "ResponseDescription" => "Accept the service request successfully."
    }
  end

  context "successful payment" do
    subject do
      stub_request(:post, %r{/mpesa/b2c/v1/paymentrequest}).to_return(
        status: 200,
        body: success_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(
        phone_number:,
        amount: 500,
        reference: "PAYOUT-001"
      )
    end

    it_behaves_like "a successful mpesa payment"
  end

  context "API error" do
    subject do
      stub_request(:post, %r{/mpesa/b2c/v1/paymentrequest}).to_return(
        status: 400,
        body: {errorMessage: "Invalid initiator credentials"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(
        phone_number:,
        amount: 500,
        reference: "PAYOUT-002"
      )
    end

    it_behaves_like "a failed mpesa API call"
  end

  context "malformed JSON response" do
    subject do
      stub_request(:post, %r{/b2c/v1/paymentrequest}).to_return(
        status: 200,
        body: "<<<NOT JSON>>>",
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(phone_number:, amount: 100, reference: "MALFORMED")
    end

    it_behaves_like "malformed mpesa response"
  end

  context "missing cert_path" do
    subject do
      Payments[:mpesa].extras.delete(:cert_path)

      described_class.call(phone_number:, amount: 1000, remarks: "Test")
    end

    it_behaves_like "mpesa certificate validation"
  end

  context "missing result_url" do
    subject do
      Payments[:mpesa].extras.delete(:result_url)

      described_class.call(phone_number:, amount: 1000, remarks: "Test")
    end

    it_behaves_like "mpesa config validation", "result_url"
  end

  describe "parameter validation" do
    it_behaves_like "a valid mpesa phone_number"
    it_behaves_like "a valid mpesa amount"
  end
end
