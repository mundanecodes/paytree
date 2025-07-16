require "base64"
require_relative "response_helpers"
require_relative "../../../utils/error_handling"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class Base
          class << self
            include Payments::Utils::ErrorHandling
            include Payments::Mpesa::Adapters::Daraja::ResponseHelpers

            def config = Payments[:mpesa]

            def connection
              @connection ||= Faraday.new(url: config.base_url) do |conn|
                conn.options.timeout = config.timeout
                conn.options.open_timeout = config.timeout / 2

                conn.request :json
                conn.response :json, content_type: "application/json"
              end
            end

            def post_to_mpesa(operation, endpoint, payload)
              build_response(
                connection.post(endpoint, payload.to_json, headers),
                operation
              )
            end

            def headers
              {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
            end

            def token
              return @token if token_valid?

              fetch_token
            end

            def encrypt_credential(config)
              cert_path = config.extras[:cert_path]
              unless cert_path && File.exist?(cert_path)
                raise Payments::Errors::MpesaCertMissing,
                  "Missing or unreadable certificate at #{cert_path}"
              end

              certificate = OpenSSL::X509::Certificate.new(File.read(cert_path))
              encrypted = certificate.public_key.public_encrypt(config.initiator_password)
              Base64.strict_encode64(encrypted)
            rescue OpenSSL::OpenSSLError => e
              raise Payments::Errors::MpesaCertMissing,
                "Failed to encrypt password with certificate #{cert_path}: #{e.message}"
            end

            # ------------------------------------------------------------------
            # Validation rules
            # ------------------------------------------------------------------
            VALIDATIONS = {
              c2b_register: {required: %i[short_code confirmation_url validation_url]},
              c2b_simulate: {required: %i[phone_number amount reference]},
              stk_push: {required: %i[phone_number amount reference]},
              b2c: {required: %i[phone_number amount], config: %i[result_url]},
              b2b: {
                required: %i[short_code receiver_shortcode account_reference amount],
                config: %i[result_url timeout_url],
                command_id: %w[BusinessPayBill BusinessBuyGoods]
              }
            }.freeze

            def validate_for(operation, params = {})
              rules = VALIDATIONS[operation] ||
                raise(Payments::Errors::UnsupportedOperation, "Unknown operation: #{operation}")

              Array(rules[:required]).each { |field| validate_field(field, params[field]) }

              Array(rules[:config]).each do |key|
                unless config.extras[key]
                  raise Payments::Errors::ConfigurationError, "Missing `#{key}` in Mpesa extras config"
                end
              end

              if (allowed = rules[:command_id]) && !allowed.include?(params[:command_id])
                raise Payments::Errors::ValidationError,
                  "command_id must be one of: #{allowed.join(", ")}"
              end
            end

            def validate_field(field, value)
              case field
              when :amount
                unless value.is_a?(Numeric) && value >= 1
                  raise Payments::Errors::ValidationError,
                    "amount must be a positive number"
                end
              when :phone_number
                phone_regex = /^254\d{9}$/
                unless value.to_s.match?(phone_regex)
                  raise Payments::Errors::ValidationError,
                    "phone_number must be a valid Kenyan format (254XXXXXXXXX)"
                end
              else
                raise Payments::Errors::ValidationError, "#{field} cannot be blank" if value.to_s.strip.empty?
              end
            end

            private

            def fetch_token
              cred = Base64.strict_encode64("#{config.key}:#{config.secret}")

              response = connection.get("/oauth/v1/generate", grant_type: "client_credentials") do |r|
                r.headers["Authorization"] = "Basic #{cred}"
              end

              data = response.body
              @token = data["access_token"]
              @token_expiry = Time.now + data["expires_in"].to_i
              @token
            rescue Faraday::Error => e
              raise Payments::Errors::MpesaTokenError, "Unable to fetch token: #{e.message}"
            end

            def token_valid?
              @token && @token_expiry && Time.now < @token_expiry
            end
          end
        end
      end
    end
  end
end
