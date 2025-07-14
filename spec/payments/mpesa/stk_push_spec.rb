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

      described_class.call(phone_number: "254712345678", amount: 100, reference: "INV-1")
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

      described_class.call(phone_number: "254712345678", amount: 10, reference: "R1")
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
        described_class.call(phone_number: "254712345678", amount: 100, reference: "INV-2")
      }.to raise_error(Faraday::ParsingError)
    end
  end

  describe "parameter validation" do
    context "phone_number validation" do
      it "raises ArgumentError when phone_number is blank" do
        expect {
          described_class.call(phone_number: "", amount: 100, reference: "INV-1")
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is nil" do
        expect {
          described_class.call(phone_number: nil, amount: 100, reference: "INV-1")
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is invalid format" do
        expect {
          described_class.call(phone_number: "0712345678", amount: 100, reference: "INV-1")
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is too short" do
        expect {
          described_class.call(phone_number: "25471234567", amount: 100, reference: "INV-1")
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is too long" do
        expect {
          described_class.call(phone_number: "2547123456789", amount: 100, reference: "INV-1")
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end
    end

    context "amount validation" do
      it "raises ArgumentError when amount is zero" do
        expect {
          described_class.call(phone_number: "254712345678", amount: 0, reference: "INV-1")
        }.to raise_error(ArgumentError, /amount must be a positive number/)
      end

      it "raises ArgumentError when amount is negative" do
        expect {
          described_class.call(phone_number: "254712345678", amount: -10, reference: "INV-1")
        }.to raise_error(ArgumentError, /amount must be a positive number/)
      end

      it "raises ArgumentError when amount is not numeric" do
        expect {
          described_class.call(phone_number: "254712345678", amount: "invalid", reference: "INV-1")
        }.to raise_error(ArgumentError, /amount must be a positive number/)
      end
    end

    context "reference validation" do
      it "raises ArgumentError when reference is blank" do
        expect {
          described_class.call(phone_number: "254712345678", amount: 100, reference: "")
        }.to raise_error(ArgumentError, /reference cannot be blank/)
      end

      it "raises ArgumentError when reference is nil" do
        expect {
          described_class.call(phone_number: "254712345678", amount: 100, reference: nil)
        }.to raise_error(ArgumentError, /reference cannot be blank/)
      end

      it "raises ArgumentError when reference is whitespace only" do
        expect {
          described_class.call(phone_number: "254712345678", amount: 100, reference: "   ")
        }.to raise_error(ArgumentError, /reference cannot be blank/)
      end
    end
  end
end
