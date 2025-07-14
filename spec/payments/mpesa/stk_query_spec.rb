RSpec.describe Payments::Mpesa::StkQuery do
  include_context "Mpesa config"

  let(:checkout_request_id) { "ws_CO_123456789" }

  context "successful query" do
    subject do
      stub_request(:post, %r{/stkpushquery}).to_return(
        status: 200,
        body: {
          "ResultCode" => "0",
          "ResultDesc" => "Processed successfully",
          "CheckoutRequestID" => checkout_request_id
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(checkout_request_id:)
    end

    it_behaves_like "a successful response", :stk_query
  end

  context "malformed JSON response" do
    it "raises Faraday::ParsingError on malformed JSON response" do
      stub_request(:post, %r{/stkpushquery}).to_return(
        status: 200,
        body: "not-a-valid-json",
        headers: {"Content-Type" => "application/json"}
      )

      expect {
        described_class.call(checkout_request_id: "ws_CO_123456789")
      }.to raise_error(Faraday::ParsingError)
    end
  end
end
