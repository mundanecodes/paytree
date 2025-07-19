RSpec.describe Paytree::Mpesa::C2B do
  include_context "Mpesa config"

  let(:short_code) { Paytree[:mpesa].shortcode }
  let(:confirmation_url) { "https://example.com/mpesa/confirm" }
  let(:validation_url) { "https://example.com/mpesa/validate" }
  let(:phone_number) { "254712345678" }

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

    context "validation errors" do
      it "raises ValidationError when short_code is blank" do
        expect {
          described_class.register_urls(
            short_code: "",
            confirmation_url:,
            validation_url:
          )
        }.to raise_error(Paytree::Errors::ValidationError, /short_code cannot be blank/)
      end

      it "raises ValidationError when confirmation_url is blank" do
        expect {
          described_class.register_urls(
            short_code:,
            confirmation_url: "",
            validation_url:
          )
        }.to raise_error(Paytree::Errors::ValidationError, /confirmation_url cannot be blank/)
      end

      it "raises ValidationError when validation_url is blank" do
        expect {
          described_class.register_urls(
            short_code:,
            confirmation_url:,
            validation_url: ""
          )
        }.to raise_error(Paytree::Errors::ValidationError, /validation_url cannot be blank/)
      end

      it "raises ValidationError when confirmation_url is nil" do
        expect {
          described_class.register_urls(
            short_code:,
            confirmation_url: nil,
            validation_url:
          )
        }.to raise_error(Paytree::Errors::ValidationError, /confirmation_url cannot be blank/)
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
      subject do
        stub_request(:post, %r{/c2b/v1/simulate}).to_return(
          status: 200,
          body: "NOT_JSON",
          headers: {"Content-Type" => "application/json"}
        )

        described_class.simulate(phone_number:, amount: 10, reference: "BAD")
      end

      it_behaves_like "malformed mpesa response"
    end

    context "validation errors" do
      it "raises ValidationError when phone_number is invalid" do
        expect {
          described_class.simulate(phone_number: "0712345678", amount: 10, reference: "TEST")
        }.to raise_error(Paytree::Errors::ValidationError, /phone_number must be a valid Kenyan format/)
      end

      it "raises ValidationError when amount is zero" do
        expect {
          described_class.simulate(phone_number:, amount: 0, reference: "TEST")
        }.to raise_error(Paytree::Errors::ValidationError, /amount must be a positive number/)
      end

      it "raises ValidationError when amount is negative" do
        expect {
          described_class.simulate(phone_number:, amount: -10, reference: "TEST")
        }.to raise_error(Paytree::Errors::ValidationError, /amount must be a positive number/)
      end

      it "raises ValidationError when reference is blank" do
        expect {
          described_class.simulate(phone_number:, amount: 10, reference: "")
        }.to raise_error(Paytree::Errors::ValidationError, /reference cannot be blank/)
      end

      it "raises ValidationError when reference is nil" do
        expect {
          described_class.simulate(phone_number:, amount: 10, reference: nil)
        }.to raise_error(Paytree::Errors::ValidationError, /reference cannot be blank/)
      end
    end
  end
end
