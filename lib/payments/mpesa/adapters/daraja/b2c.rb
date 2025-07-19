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
                  Remarks: opts[:remarks] || "OK",
                  Occasion: opts[:occasion] || "Payment"
                }.compact

                post_to_mpesa(:b2c, ENDPOINT, payload)
              end
            end
          end
        end
      end
    end
  end
end
