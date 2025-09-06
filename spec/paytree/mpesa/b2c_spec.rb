require "spec_helper"

RSpec.describe Paytree::Mpesa::B2C do
  include_context "Mpesa config"

  let(:phone_number) { "254712345678" }

  shared_examples "b2c payment request" do |api_version|
    let(:expected_endpoint) { "/mpesa/b2c/#{api_version}/paymentrequest" }
  end

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

    it_behaves_like "a successful mpesa payment"
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

    it_behaves_like "a failed mpesa API call"
  end

  context "malformed JSON response" do
    subject do
      stub_request(:post, %r{/b2c/v1/paymentrequest}).to_return(
        status: 200,
        body: "<<<NOT JSON>>>",
        headers: {"Content-Type" => "application/json"}
      )

      described_class.call(phone_number:, amount: 100, reference: "MALFORMED")
    end

    it_behaves_like "malformed mpesa response"
  end

  context "missing cert_path" do
    subject do
      Paytree[:mpesa].extras.delete(:cert_path)

      described_class.call(phone_number:, amount: 1000, remarks: "Test")
    end

    it_behaves_like "mpesa certificate validation"
  end

  context "missing result_url" do
    subject do
      Paytree[:mpesa].extras.delete(:result_url)

      described_class.call(phone_number:, amount: 1000, remarks: "Test")
    end

    it_behaves_like "mpesa config validation", "result_url"
  end

  describe "parameter validation" do
    it_behaves_like "a valid mpesa phone_number"
    it_behaves_like "a valid mpesa amount"
  end

  describe "API version support" do
    context "when using v1 API (default)" do
      before do
        Paytree[:mpesa].api_version = "v1"
      end

      subject do
        stub_request(:post, %r{/mpesa/b2c/v1/paymentrequest}).to_return(
          status: 200,
          body: success_body.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        described_class.call(
          phone_number:,
          amount: 500,
          reference: "V1-TEST"
        )
      end

      it "uses v1 endpoint" do
        subject
        expect(WebMock).to have_requested(:post, %r{/mpesa/b2c/v1/paymentrequest})
      end

      it "does not include OriginatorConversationID in payload" do
        subject
        expect(WebMock).to have_requested(:post, %r{/mpesa/b2c/v1/paymentrequest}).with { |req|
          payload = JSON.parse(req.body)
          !payload.key?("OriginatorConversationID")
        }
      end
    end

    context "when using v3 API" do
      before do
        Paytree[:mpesa].api_version = "v3"
      end

      subject do
        stub_request(:post, %r{/mpesa/b2c/v3/paymentrequest}).to_return(
          status: 200,
          body: success_body.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        described_class.call(
          phone_number:,
          amount: 500,
          reference: "V3-TEST"
        )
      end

      it "uses v3 endpoint" do
        subject
        expect(WebMock).to have_requested(:post, %r{/mpesa/b2c/v3/paymentrequest})
      end

      it "includes auto-generated OriginatorConversationID in payload" do
        subject
        expect(WebMock).to have_requested(:post, %r{/mpesa/b2c/v3/paymentrequest}).with { |req|
          payload = JSON.parse(req.body)
          payload.key?("OriginatorConversationID") && !payload["OriginatorConversationID"].nil?
        }
      end

      it "uses custom OriginatorConversationID when provided" do
        custom_id = "custom-conversation-id-123"

        stub_request(:post, %r{/mpesa/b2c/v3/paymentrequest}).to_return(
          status: 200,
          body: success_body.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        described_class.call(
          phone_number:,
          amount: 500,
          reference: "V3-CUSTOM",
          originator_conversation_id: custom_id
        )

        expect(WebMock).to have_requested(:post, %r{/mpesa/b2c/v3/paymentrequest}).with { |req|
          payload = JSON.parse(req.body)
          payload["OriginatorConversationID"] == custom_id
        }
      end
    end
  end
end
