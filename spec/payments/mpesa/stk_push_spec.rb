require "spec_helper"

RSpec.describe Payments::Mpesa::StkPush do
  include_context "Mpesa config"

  let(:success_body) do
    {
      "MerchantRequestID" => "12345",
      "CheckoutRequestID" => "ws_CO_123456789",
      "ResponseCode" => "0",
      "ResponseDescription" => "Success",
      "CustomerMessage" => "Success"
    }
  end

  context "successful push" do
    subject do
      stub_request(:post, %r{/mpesa/stkpush/v1/processrequest}).to_return(
        status: 200,
        body: success_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(
        phone_number: "+254712345678",
        amount: 100,
        reference: "INV-1"
      )
    end

    it_behaves_like "a successful STK Push"
  end

  context "API error" do
    subject do
      stub_request(:post, %r{/mpesa/stkpush/v1/processrequest}).to_return(
        status: 400,
        body: {"errorCode" => "500.001.1001", "errorMessage" => "Invalid token"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(
        phone_number: "+254712345678",
        amount: 100,
        reference: "INV-1"
      )
    end

    it "marks response as error" do
      expect(subject).to be_error
      expect(subject.message).to eq("Invalid token")
    end
  end
end
