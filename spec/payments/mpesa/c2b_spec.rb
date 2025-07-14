RSpec.describe Payments::Mpesa::C2B do
  include_context "Mpesa config"

  let(:short_code) { Payments[:mpesa].shortcode }
  let(:confirmation_url) { "https://example.com/mpesa/confirm" }
  let(:validation_url) { "https://example.com/mpesa/validate" }
  let(:phone_number) { "+254712345678" }

  describe ".register_urls" do
    context "success" do
      subject do
        stub_request(:post, %r{/c2b/v1/registerurl}).to_return(
          status: 200,
          body: {ResponseDescription: "Success", ResponseCode: "0"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
        described_class.register_urls(
          short_code:,
          confirmation_url:,
          validation_url:
        )
      end

      it_behaves_like "a successful response", :c2b_register
    end

    context "missing confirmation_url" do
      it "raises ArgumentError" do
        expect {
          described_class.register_urls(
            short_code:,
            confirmation_url: nil,
            validation_url:
          )
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".simulate" do
    context "sandbox success" do
      subject do
        stub_request(:post, %r{/c2b/v1/simulate}).to_return(
          status: 200,
          body: {CustomerMessage: "Success", ResponseCode: "0"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
        described_class.simulate(
          phone_number:,
          amount: 50,
          reference: "TEST123"
        )
      end

      it_behaves_like "a successful response", :c2b_simulate
    end

    context "malformed JSON response" do
      it "raises Faraday::ParsingError" do
        stub_request(:post, %r{/c2b/v1/simulate}).to_return(
          status: 200,
          body: "NOT_JSON",
          headers: {"Content-Type" => "application/json"}
        )

        expect {
          described_class.simulate(phone_number:, amount: 10, reference: "BAD")
        }.to raise_error(Faraday::ParsingError)
      end
    end
  end
end
