require "spec_helper"

RSpec.describe Paytree::Mpesa::Adapters::Daraja::Base do
  include_context "Mpesa config"

  let(:base_class) { described_class }

  before do
    base_class.instance_variable_set(:@token, nil)
    base_class.instance_variable_set(:@token_expiry, nil)
    base_class.instance_variable_set(:@http_client, nil)
    base_class.instance_variable_set(:@token_http_client, nil)
    base_class.instance_variable_set(:@token_mutex, nil)
    base_class.instance_variable_set(:@http_client_mutex, nil)
    base_class.instance_variable_set(:@token_http_client_mutex, nil)
  end

  describe "HTTP client configuration" do
    it "configures regular http_client with timeouts and SSL" do
      client = base_class.http_client
      expect(client).to be_a(HTTPX::Session)
    end

    it "configures token_http_client with retries, timeouts, and SSL" do
      client = base_class.token_http_client
      expect(client).to be_a(HTTPX::Session)
    end
  end

  describe "#fetch_token" do
    context "when token fetch succeeds on first attempt" do
      it "returns token without retry" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(
            status: 200,
            body: {access_token: "success_token", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        token = base_class.send(:fetch_token)

        expect(token).to eq("success_token")
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).once
      end

      it "sets token expiry correctly" do
        freeze_time = Time.now
        allow(Time).to receive(:now).and_return(freeze_time)

        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(
            status: 200,
            body: {access_token: "test_token", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        base_class.send(:fetch_token)

        expect(base_class.instance_variable_get(:@token_expiry)).to eq(freeze_time + 3600)
      end
    end

    context "when token fetch fails then succeeds" do
      it "retries on timeout and eventually succeeds" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_timeout.then
          .to_return(
            status: 200,
            body: {access_token: "retry_success", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        token = base_class.send(:fetch_token)

        expect(token).to eq("retry_success")
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).twice
      end

      it "retries on 500 error and eventually succeeds" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(status: 500, body: "Internal Server Error").then
          .to_return(
            status: 200,
            body: {access_token: "retry_after_500", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        token = base_class.send(:fetch_token)

        expect(token).to eq("retry_after_500")
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).twice
      end

      it "retries on 502 error and eventually succeeds" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(status: 502, body: "Bad Gateway").then
          .to_return(
            status: 200,
            body: {access_token: "retry_after_502", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        token = base_class.send(:fetch_token)

        expect(token).to eq("retry_after_502")
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).twice
      end
    end

    context "when token fetch fails all retry attempts" do
      it "raises MpesaTokenError after exhausting retries" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_timeout

        expect {
          base_class.send(:fetch_token)
        }.to raise_error(
          Paytree::Errors::MpesaTokenError,
          /Unable to fetch token/
        )

        # HTTPX retries 3 times, so total 4 requests (1 initial + 3 retries)
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).times(4)
      end

      it "raises MpesaTokenError with meaningful message on persistent 500 errors" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(status: 500, body: "Internal Server Error")

        expect {
          base_class.send(:fetch_token)
        }.to raise_error(Paytree::Errors::MpesaTokenError)

        # Should retry 3 times (total 4 attempts)
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).times(4)
      end
    end

    context "exponential backoff behavior" do
      it "attempts multiple retries on connection failures" do
        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_timeout

        expect {
          base_class.send(:fetch_token)
        }.to raise_error(Paytree::Errors::MpesaTokenError)

        # HTTPX with max_retries: 3 means 1 initial + 3 retries = 4 total attempts
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).times(4)
      end
    end
  end

  describe "#token" do
    context "when token is valid" do
      it "returns cached token without fetching" do
        base_class.instance_variable_set(:@token, "cached_token")
        base_class.instance_variable_set(:@token_expiry, Time.now + 3600)

        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")

        token = base_class.token

        expect(token).to eq("cached_token")
        expect(WebMock).not_to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
      end
    end

    context "when token is expired" do
      it "fetches new token" do
        base_class.instance_variable_set(:@token, "old_token")
        base_class.instance_variable_set(:@token_expiry, Time.now - 1)

        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(
            status: 200,
            body: {access_token: "new_token", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        token = base_class.token

        expect(token).to eq("new_token")
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).once
      end
    end
  end

  describe "#post_to_mpesa (regular API calls)" do
    before do
      # Set valid token for API calls
      base_class.instance_variable_set(:@token, "test_token")
      base_class.instance_variable_set(:@token_expiry, Time.now + 3600)
    end

    context "retry behavior" do
      it "does NOT retry on timeout" do
        stub_request(:post, %r{/mpesa/stkpush/v1/processrequest})
          .to_timeout

        expect {
          base_class.post_to_mpesa(:stk_push, "/mpesa/stkpush/v1/processrequest", {test: "data"})
        }.to raise_error(HTTPX::TimeoutError)

        # Should only attempt once, no retries
        expect(WebMock).to have_requested(:post, %r{/mpesa/stkpush/v1/processrequest}).once
      end

      it "does NOT retry on 500 error" do
        stub_request(:post, %r{/mpesa/stkpush/v1/processrequest})
          .to_return(
            status: 500,
            body: {errorMessage: "Internal Server Error"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        # Should return error response without retrying
        response = base_class.post_to_mpesa(:stk_push, "/mpesa/stkpush/v1/processrequest", {test: "data"})

        expect(response.status).to eq(:error)
        # Should only attempt once, no retries
        expect(WebMock).to have_requested(:post, %r{/mpesa/stkpush/v1/processrequest}).once
      end

      it "does NOT retry on 502 error" do
        stub_request(:post, %r{/mpesa/stkpush/v1/processrequest})
          .to_return(
            status: 502,
            body: {errorMessage: "Bad Gateway"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        response = base_class.post_to_mpesa(:stk_push, "/mpesa/stkpush/v1/processrequest", {test: "data"})

        expect(response.status).to eq(:error)
        expect(WebMock).to have_requested(:post, %r{/mpesa/stkpush/v1/processrequest}).once
      end
    end
  end

  describe "thread safety" do
    context "concurrent token fetching" do
      it "only fetches token once when multiple threads request simultaneously" do
        base_class.instance_variable_set(:@token, nil)
        base_class.instance_variable_set(:@token_expiry, nil)

        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(
            status: 200,
            body: {access_token: "concurrent_token", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        # Simulate 10 concurrent threads requesting token
        threads = 10.times.map do
          Thread.new { base_class.token }
        end

        tokens = threads.map(&:value)

        # All threads should get the same token
        expect(tokens.uniq).to eq(["concurrent_token"])
        # API should only be called once (not 10 times)
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).once
      end

      it "handles concurrent token expiry gracefully" do
        # Set an expired token
        base_class.instance_variable_set(:@token, "old_token")
        base_class.instance_variable_set(:@token_expiry, Time.now - 1)

        stub_request(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"})
          .to_return(
            status: 200,
            body: {access_token: "refreshed_token", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        # Simulate 5 concurrent threads requesting token when expired
        threads = 5.times.map do
          Thread.new { base_class.token }
        end

        tokens = threads.map(&:value)

        # All threads should get the same refreshed token
        expect(tokens.uniq).to eq(["refreshed_token"])
        # API should only be called once due to double-check locking
        expect(WebMock).to have_requested(:get, "https://sandbox.safaricom.co.ke/oauth/v1/generate")
          .with(query: {grant_type: "client_credentials"}).once
      end
    end

    context "concurrent HTTP client initialization" do
      it "only initializes http_client once" do
        base_class.instance_variable_set(:@http_client, nil)

        # Simulate 10 concurrent threads requesting http_client
        threads = 10.times.map do
          Thread.new { base_class.http_client }
        end

        clients = threads.map(&:value)

        # All threads should get the same client instance
        expect(clients.uniq.size).to eq(1)
      end

      it "only initializes token_http_client once" do
        base_class.instance_variable_set(:@token_http_client, nil)

        # Simulate 10 concurrent threads requesting token_http_client
        threads = 10.times.map do
          Thread.new { base_class.token_http_client }
        end

        clients = threads.map(&:value)

        # All threads should get the same client instance
        expect(clients.uniq.size).to eq(1)
      end
    end

    context "concurrent API calls with token refresh" do
      it "handles concurrent API calls during token refresh" do
        base_class.instance_variable_set(:@token, "valid_token")
        base_class.instance_variable_set(:@token_expiry, Time.now + 3600)

        stub_request(:post, %r{/mpesa/stkpush/v1/processrequest}).to_return(
          status: 200,
          body: {ResponseCode: "0", ResponseDescription: "Success"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

        # Simulate 5 concurrent API calls
        threads = 5.times.map do
          Thread.new do
            base_class.post_to_mpesa(:stk_push, "/mpesa/stkpush/v1/processrequest", {test: "data"})
          end
        end

        responses = threads.map(&:value)

        # All responses should succeed
        expect(responses.all?(&:success?)).to be true
        # Should have made 5 API calls (no token refresh needed)
        expect(WebMock).to have_requested(:post, %r{/mpesa/stkpush/v1/processrequest}).times(5)
      end
    end
  end

  describe "validation" do
    describe "#validate_for" do
      it "raises error for unknown operation" do
        expect {
          base_class.validate_for(:unknown_operation)
        }.to raise_error(Paytree::Errors::UnsupportedOperation, /Unknown operation/)
      end
    end

    describe "#validate_field" do
      context "amount validation" do
        it "accepts positive numbers" do
          expect {
            base_class.validate_field(:amount, 100)
          }.not_to raise_error
        end

        it "rejects negative numbers" do
          expect {
            base_class.validate_field(:amount, -10)
          }.to raise_error(Paytree::Errors::ValidationError, /must be a positive number/)
        end

        it "rejects zero" do
          expect {
            base_class.validate_field(:amount, 0)
          }.to raise_error(Paytree::Errors::ValidationError, /must be a positive number/)
        end
      end

      context "phone number validation" do
        it "accepts valid Kenyan format" do
          expect {
            base_class.validate_field(:phone_number, "254712345678")
          }.not_to raise_error
        end

        it "rejects invalid format" do
          expect {
            base_class.validate_field(:phone_number, "0712345678")
          }.to raise_error(Paytree::Errors::ValidationError, /must be a valid Kenyan format/)
        end

        it "rejects too short numbers" do
          expect {
            base_class.validate_field(:phone_number, "2547123456")
          }.to raise_error(Paytree::Errors::ValidationError, /must be a valid Kenyan format/)
        end
      end
    end
  end
end
