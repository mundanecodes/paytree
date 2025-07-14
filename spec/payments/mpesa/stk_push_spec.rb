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
      stub_request(:post, %r{/stkpush/v1/processrequest}).to_return(
        status: 200, body: success_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(phone_number: "+254712345678", amount: 100, reference: "INV-1")
    end

    it_behaves_like "a successful response", :stk_push
  end

  context "token expiry refreshes automatically" do
    subject do
      Payments::Mpesa::Adapters::Daraja::Base.instance_variable_set(:@token, "old")
      Payments::Mpesa::Adapters::Daraja::Base.instance_variable_set(:@token_expiry, Time.now - 10)

      stub_request(:get, %r{/oauth/v1/generate}).to_return(
        status: 200,
        body: {access_token: "new_token", expires_in: 3600}.to_json
      )

      stub_request(:post, %r{/stkpush/v1/processrequest}).to_return(
        status: 200, body: success_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(phone_number: "+2547...", amount: 10, reference: "R1")
    end

    it_behaves_like "a successful response", :stk_push
  end

  context "malformed JSON body" do
    it "raises Faraday::ParsingError on malformed response" do
      stub_request(:post, %r{/mpesa/stkpush/v1/processrequest}).to_return(
        status: 200,
        body: "this-is-not-json",
        headers: {"Content-Type" => "application/json"}
      )

      expect {
        described_class.call(phone_number: "+254712345678", amount: 100, reference: "INV-2")
      }.to raise_error(Faraday::ParsingError)
    end
  end
end
