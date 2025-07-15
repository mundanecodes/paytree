RSpec.describe Payments::Mpesa::B2B do
  include_context "Mpesa config"

  let(:short_code) { "600999" }
  let(:receiver_shortcode) { "600111" }

  let(:success_body) do
    {
      "ResponseDescription" => "Accept the service request successfully.",
      "ResponseCode" => "0",
      "OriginatorConversationID" => "AG_123456789"
    }
  end

  context "successful payment" do
    subject do
      stub_request(:post, %r{/b2b/v1/paymentrequest}).to_return(
        status: 200,
        body: success_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(
        short_code:,
        receiver_shortcode:,
        amount: 100,
        account_reference: "REF-123"
      )
    end

    it_behaves_like "a successful response", :b2b
  end

  context "malformed JSON response" do
    subject do
      stub_request(:post, %r{/b2b/v1/paymentrequest}).to_return(
        status: 200,
        body: "NOT_JSON",
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(
        short_code:,
        receiver_shortcode:,
        amount: 100,
        account_reference: "BROKEN"
      )
    end

    it_behaves_like "malformed mpesa response"
  end

  context "missing cert file" do
    subject do
      allow(File).to receive(:exist?).and_return(false)

      described_class.call(
        short_code:,
        receiver_shortcode:,
        amount: 100,
        account_reference: "NO_CERT"
      )
    end

    it_behaves_like "mpesa certificate validation"
  end

  describe "parameter validation" do
    context "short_code validation" do
      it "raises ValidationError when blank" do
        expect {
          described_class.call(short_code: "", receiver_shortcode:, amount: 100, account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /short_code cannot be blank/)
      end

      it "raises ValidationError when nil" do
        expect {
          described_class.call(short_code: nil, receiver_shortcode:, amount: 100, account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /short_code cannot be blank/)
      end

      it "raises ValidationError when whitespace only" do
        expect {
          described_class.call(short_code: "   ", receiver_shortcode:, amount: 100, account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /short_code cannot be blank/)
      end
    end

    context "receiver_shortcode validation" do
      it "raises ValidationError when blank" do
        expect {
          described_class.call(short_code:, receiver_shortcode: "", amount: 100, account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /receiver_shortcode cannot be blank/)
      end
    end

    context "account_reference validation" do
      it "raises ValidationError when blank" do
        expect {
          described_class.call(short_code:, receiver_shortcode:, amount: 100, account_reference: "")
        }.to raise_error(Payments::Errors::ValidationError, /account_reference cannot be blank/)
      end
    end

    context "amount validation" do
      it "raises ValidationError when amount is zero" do
        expect {
          described_class.call(short_code:, receiver_shortcode:, amount: 0, account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /amount must be a positive number/)
      end

      it "raises ValidationError when amount is negative" do
        expect {
          described_class.call(short_code:, receiver_shortcode:, amount: -10, account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /amount must be a positive number/)
      end

      it "raises ValidationError when amount is not numeric" do
        expect {
          described_class.call(short_code:, receiver_shortcode:, amount: "invalid", account_reference: "REF-123")
        }.to raise_error(Payments::Errors::ValidationError, /amount must be a positive number/)
      end
    end

    context "command_id validation" do
      it "raises ValidationError when invalid" do
        expect {
          described_class.call(
            short_code:,
            receiver_shortcode:,
            amount: 100,
            account_reference: "REF-123",
            command_id: "InvalidCommand"
          )
        }.to raise_error(Payments::Errors::ValidationError, /command_id must be one of: BusinessPayBill, BusinessBuyGoods/)
      end

      it "accepts valid command_id BusinessPayBill" do
        stub_request(:post, %r{/b2b/v1/paymentrequest}).to_return(
          status: 200,
          body: success_body.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        expect {
          described_class.call(
            short_code:,
            receiver_shortcode:,
            amount: 100,
            account_reference: "REF-123",
            command_id: "BusinessPayBill"
          )
        }.not_to raise_error
      end

      it "accepts valid command_id BusinessBuyGoods" do
        stub_request(:post, %r{/b2b/v1/paymentrequest}).to_return(
          status: 200,
          body: success_body.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        expect {
          described_class.call(
            short_code:,
            receiver_shortcode:,
            amount: 100,
            account_reference: "REF-123",
            command_id: "BusinessBuyGoods"
          )
        }.not_to raise_error
      end
    end

    context "config validation" do
      it "raises ConfigurationError when result_url is missing" do
        config = Payments[:mpesa]
        config.extras.delete(:result_url)

        expect {
          described_class.call(
            short_code:,
            receiver_shortcode:,
            amount: 100,
            account_reference: "REF-123"
          )
        }.to raise_error(Payments::Errors::ConfigurationError, /Missing `result_url` in Mpesa extras config/)
      end

      it "raises ConfigurationError when timeout_url is missing" do
        config = Payments[:mpesa]
        config.extras.delete(:timeout_url)

        expect {
          described_class.call(
            short_code:,
            receiver_shortcode:,
            amount: 100,
            account_reference: "REF-123"
          )
        }.to raise_error(Payments::Errors::ConfigurationError, /Missing `timeout_url` in Mpesa extras config/)
      end
    end
  end
end
