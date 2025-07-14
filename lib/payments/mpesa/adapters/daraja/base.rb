require "base64"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class Base
          class << self
            def connection
              config = Payments[:mpesa]
              @connection ||= Faraday.new(url: config.base_url) do |conn|
                conn.request :json
                conn.response :json, content_type: "application/json"
              end
            end

            def token
              return @token if token_valid?

              fetch_token
            end

            def headers
              {
                "Authorization" => "Bearer #{token}",
                "Content-Type" => "application/json"
              }
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

            private

            def fetch_token
              config = Payments[:mpesa]
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
