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

    it "returns a success response" do
      expect(subject).to be_success
      expect(subject.data["ResponseDescription"]).to match(/Accept/)
    end
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

    it "marks the response as error" do
      expect(subject).to be_error
      expect(subject.message).to eq("Invalid initiator credentials")
    end
  end

  context "malformed JSON response" do
    it "raises JSON::ParserError or Faraday::ParsingError" do
      stub_request(:post, %r{/b2c/v1/paymentrequest}).to_return(
        status: 200,
        body: "<<<NOT JSON>>>",
        headers: {"Content-Type" => "application/json"}
      )

      expect {
        described_class.call(phone_number:, amount: 100, reference: "MALFORMED")
      }.to raise_error(Faraday::ParsingError)
    end
  end

  context "missing cert_path" do
    before do
      config = Payments[:mpesa]
      config.extras.delete(:cert_path)
    end

    it "raises ArgumentError" do
      expect {
        described_class.call(phone_number:, amount: 1000, remarks: "Test")
      }.to raise_error(ArgumentError, /cert_path/)
    end
  end

  context "missing result_url" do
    before do
      config = Payments[:mpesa]
      config.extras.delete(:result_url)
    end

    it "raises ArgumentError" do
      expect {
        described_class.call(phone_number:, amount: 1000, remarks: "Test")
      }.to raise_error(ArgumentError, /result_url/)
    end
  end

  describe "parameter validation" do
    context "phone_number validation" do
      it "raises ArgumentError when phone_number is blank" do
        expect {
          described_class.call(phone_number: "", amount: 100)
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is nil" do
        expect {
          described_class.call(phone_number: nil, amount: 100)
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is invalid format" do
        expect {
          described_class.call(phone_number: "0712345678", amount: 100)
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is too short" do
        expect {
          described_class.call(phone_number: "25471234567", amount: 100)
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ArgumentError when phone_number is too long" do
        expect {
          described_class.call(phone_number: "2547123456789", amount: 100)
        }.to raise_error(ArgumentError, /phone_number must be a valid Kenyan format/)
      end

      it "accepts valid phone_number format" do
        stub_request(:post, %r{/b2c/v1/paymentrequest}).to_return(
          status: 200,
          body: success_body.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        expect {
          described_class.call(phone_number: "254712345678", amount: 100)
        }.not_to raise_error
      end
    end

    context "amount validation" do
      it "raises ArgumentError when amount is zero" do
        expect {
          described_class.call(phone_number:, amount: 0)
        }.to raise_error(ArgumentError, /amount must be a positive number/)
      end

      it "raises ArgumentError when amount is negative" do
        expect {
          described_class.call(phone_number:, amount: -10)
        }.to raise_error(ArgumentError, /amount must be a positive number/)
      end

      it "raises ArgumentError when amount is not numeric" do
        expect {
          described_class.call(phone_number:, amount: "invalid")
        }.to raise_error(ArgumentError, /amount must be a positive number/)
      end
    end
  end
end
