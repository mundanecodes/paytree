require "base64"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class Base
          class << self
            def config = Payments[:mpesa]

            def connection
              @connection ||= Faraday.new(url: config.base_url) do |conn|
                conn.request :json
                conn.response :json, content_type: "application/json"
              end
            end

            def headers
              {
                "Authorization" => "Bearer #{token}",
                "Content-Type" => "application/json"
              }
            end

            def token
              return @token if token_valid?

              fetch_token
            end

            def encrypt_credential(config)
              cert_path = config.extras[:cert_path]
              raise ArgumentError, "Missing `cert_path` in Mpesa extras config" unless cert_path && File.exist?(cert_path)

              begin
                certificate = OpenSSL::X509::Certificate.new(File.read(cert_path))
                public_key = certificate.public_key
                encrypted = public_key.public_encrypt(config.initiator_password)
                Base64.strict_encode64(encrypted)
              rescue OpenSSL::OpenSSLError => e
                raise "Failed to encrypt initiator password using certificate at #{cert_path}: #{e.message}"
              end
            end

            VALIDATIONS = {
              c2b_register: {required: [:short_code, :confirmation_url, :validation_url]},
              c2b_simulate: {required: [:phone_number, :amount, :reference]},
              stk_push: {required: [:phone_number, :amount, :reference]},
              b2c: {required: [:phone_number, :amount], config: [:result_url]},
              b2b: {
                required: [:short_code, :receiver_shortcode, :account_reference, :amount],
                config: [:result_url, :timeout_url],
                command_id: %w[BusinessPayBill BusinessBuyGoods]
              }
            }.freeze

            def validate_for(operation, params = {})
              rules = VALIDATIONS[operation]
              raise ArgumentError, "Unknown operation: #{operation}" unless rules

              Array(rules[:required]).each { validate_field(it, params[it]) }
              Array(rules[:config]).each { raise ArgumentError, "Missing `#{it}` in Mpesa extras config" unless config.extras[it] }

              if rules[:command_id] && params[:command_id]
                unless rules[:command_id].include?(params[:command_id])
                  raise ArgumentError, "command_id must be one of: #{rules[:command_id].join(", ")}"
                end
              end
            end

            def validate_field(field, value)
              case field
              when :amount
                unless value.is_a?(Numeric) && value >= 1
                  raise ArgumentError, "amount must be a positive number"
                end
              when :phone_number
                unless value.to_s.match?(/^254\d{9}$/)
                  raise ArgumentError, "phone_number must be a valid Kenyan format (254XXXXXXXXX)"
                end
              else
                if value.to_s.strip.empty?
                  raise ArgumentError, "#{field} cannot be blank"
                end
              end
            end

            private

            def fetch_token
              cred = Base64.strict_encode64("#{config.key}:#{config.secret}")

              resp = connection.get("/oauth/v1/generate", grant_type: "client_credentials") do |r|
                r.headers["Authorization"] = "Basic #{cred}"
              end

              data = resp.body
              @token = data["access_token"]
              @token_expiry = Time.now + data["expires_in"].to_i
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
end
