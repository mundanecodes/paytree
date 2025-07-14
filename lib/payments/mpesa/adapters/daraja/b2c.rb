require "payments/mpesa/adapters/daraja/base"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class B2C < Base
          ENDPOINT = "/mpesa/b2c/v1/paymentrequest"

          class << self
            def call(phone_number:, amount:, **opts)
              config = Payments[:mpesa]

              raise ArgumentError, "Missing `result_url` in Mpesa extras config" unless config.extras[:result_url]

              payload = {
                InitiatorName: config.initiator_name,
                SecurityCredential: encrypt_credential(config),
                Amount: amount,
                PartyA: config.shortcode,
                PartyB: phone_number,
                QueueTimeOutURL: config.extras[:timeout_url],
                ResultURL: config.extras[:result_url],
                CommandID: opts[:command_id] || "BusinessPayment",
                Remarks: opts[:remarks],
                Occasion: opts[:occasion]
              }.compact

              response = connection.post(ENDPOINT, payload.to_json, headers)
              build_response(response)
            end

            private

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

            def build_response(response)
              parsed = response.body

              Payments::Response.new(
                provider: :mpesa,
                operation: :b2c,
                status: response.success? ? :success : :error,
                message: parsed["ResponseDescription"] || parsed["errorMessage"],
                code: parsed["ResponseCode"] || parsed["errorCode"],
                data: parsed,
                raw_response: response
              )
            end
          end
        end
      end
    end
  end
end
