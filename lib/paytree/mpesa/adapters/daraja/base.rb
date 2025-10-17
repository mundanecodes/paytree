require "base64"
require "securerandom"
require_relative "response_helpers"
require_relative "http_client_factory"
require_relative "validator"
require_relative "token_manager"
require_relative "../../../utils/error_handling"

module Paytree
  module Mpesa
    module Adapters
      module Daraja
        class Base
          class << self
            include Paytree::Utils::ErrorHandling
            include Paytree::Mpesa::Adapters::Daraja::ResponseHelpers
            include Paytree::Mpesa::Adapters::Daraja::HttpClientFactory
            include Paytree::Mpesa::Adapters::Daraja::Validator
            include Paytree::Mpesa::Adapters::Daraja::TokenManager

            def config = Paytree[:mpesa]

            # Thread-safe HTTP client for regular API calls
            def http_client
              thread_safe_client(:@http_client)
            end

            # Thread-safe HTTP client with retry logic for token fetching
            # Retries on: timeouts, connection errors, and 5xx server errors
            def token_http_client
              thread_safe_client(:@token_http_client, plugins: [:retries], **retry_options)
            end

            def post_to_mpesa(operation, endpoint, payload)
              response = http_client.post(endpoint, json: payload, headers:)
              build_response(response, operation)
            end

            def headers
              {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
            end

            def encrypt_credential(config)
              cert_path = config.extras[:cert_path]
              unless cert_path && File.exist?(cert_path)
                raise Paytree::Errors::MpesaCertMissing,
                  "Missing or unreadable certificate at #{cert_path}"
              end

              certificate = OpenSSL::X509::Certificate.new(File.read(cert_path))
              encrypted = certificate.public_key.public_encrypt(config.initiator_password)
              Base64.strict_encode64(encrypted)
            rescue OpenSSL::OpenSSLError => e
              raise Paytree::Errors::MpesaCertMissing,
                "Failed to encrypt password with certificate #{cert_path}: #{e.message}"
            end

            def generate_conversation_id
              SecureRandom.uuid
            end
          end
        end
      end
    end
  end
end
