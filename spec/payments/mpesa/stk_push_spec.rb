require "spec_helper"

RSpec.describe Payments::Mpesa::StkPush do
  before do
    stub_request(:get, %r{/oauth/v1/generate}).to_return(
      status: 200,
      body: {access_token: "test_token", expires_in: 3600}.to_json,
      headers: {"Content-Type" => "application/json"}
    )

    Payments::Mpesa::Adapters::Daraja::Base.instance_variable_set(:@token, nil)
    Payments::Mpesa::Adapters::Daraja::Base.instance_variable_set(:@token_expiry, nil)

    Payments.configure(:mpesa, Payments::Configs::Mpesa) do |config|
      config[:key] = "TEST_KEY"
      config[:secret] = "TEST_SECRET"
      config[:shortcode] = "600999"
      config[:passkey] = "PASSKEY"
      config[:sandbox] = true
      config[:extras] = {callback_url: "https://example.com/callback"}
      config[:adapter] = Payments::Mpesa::Adapters::Daraja
    end
  end

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
