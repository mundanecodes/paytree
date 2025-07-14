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
    it "raises Faraday::ParsingError" do
      stub_request(:post, %r{/b2b/v1/paymentrequest}).to_return(
        status: 200,
        body: "NOT_JSON",
        headers: {"Content-Type" => "application/json"}
      )

      expect {
        described_class.call(
          short_code:,
          receiver_shortcode:,
          amount: 100,
          account_reference: "BROKEN"
        )
      }.to raise_error(Faraday::ParsingError)
    end
  end

  context "missing cert file" do
    it "raises ArgumentError" do
      allow(File).to receive(:exist?).and_return(false)

      expect {
        described_class.call(
          short_code:,
          receiver_shortcode:,
          amount: 100,
          account_reference: "NO_CERT"
        )
      }.to raise_error(ArgumentError, /cert_path/)
    end
  end
end
