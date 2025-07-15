require "payments/mpesa/adapters/daraja/base"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class B2C < Base
          ENDPOINT = "/mpesa/b2c/v1/paymentrequest"

          class << self
            def call(phone_number:, amount:, **opts)
              with_error_handling(context: :b2c) do
                config = self.config
                validate_for(:b2c, phone_number:, amount:)

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
            end

            private

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
