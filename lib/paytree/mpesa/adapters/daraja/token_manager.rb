require "base64"

module Paytree
  module Mpesa
    module Adapters
      module Daraja
        # Thread-safe token management for M-Pesa Daraja API
        # Handles OAuth token fetching, caching, and expiry validation
        module TokenManager
          # Returns a valid access token, fetching a new one if needed
          # @return [String] Valid access token
          def token
            return @token if token_valid?

            @token_mutex ||= Mutex.new
            @token_mutex.synchronize do
              return @token if token_valid?

              fetch_token
            end
          end

          private

          # Fetches a new OAuth token from M-Pesa API
          # Automatically retries on network errors and 5xx responses
          # @return [String] Access token
          # @raise [Paytree::Errors::MpesaTokenError] if token fetch fails
          def fetch_token
            credentials = encode_credentials

            response = token_http_client.get(
              "/oauth/v1/generate",
              params: {grant_type: "client_credentials"},
              headers: {"Authorization" => "Basic #{credentials}"}
            )

            validate_token_response(response)
            parse_and_cache_token(response)
          rescue HTTPX::Error => e
            raise Paytree::Errors::MpesaTokenError, "Unable to fetch token: #{e.message}"
          end

          def encode_credentials
            Base64.strict_encode64("#{config.key}:#{config.secret}")
          end

          def validate_token_response(response)
            if response.is_a?(HTTPX::ErrorResponse) || response.error
              error_msg = response.error ? response.error.message : "Request failed"
              raise Paytree::Errors::MpesaTokenError, "Unable to fetch token: #{error_msg}"
            end

            unless response.status == 200
              raise Paytree::Errors::MpesaTokenError,
                "Token request failed with status #{response.status}"
            end
          end

          def parse_and_cache_token(response)
            response_data = response.json
            @token = response_data["access_token"]
            @token_expiry = Time.now + response_data["expires_in"].to_i
            @token
          end

          def token_valid?
            @token && @token_expiry && Time.now < @token_expiry
          end
        end
      end
    end
  end
end
