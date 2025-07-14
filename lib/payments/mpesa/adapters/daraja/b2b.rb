require "payments/mpesa/adapters/daraja/base"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class B2B < Base
          ENDPOINT = "/mpesa/b2b/v1/paymentrequest"

          class << self
            def call(short_code:, receiver_shortcode:, amount:, account_reference:, **opts)
              command_id = opts[:command_id] || "BusinessPayBill"

              validate_for(:b2b, short_code:, receiver_shortcode:, account_reference:, amount:, command_id:)

              payload = {
                Initiator: config.initiator_name,
                SecurityCredential: encrypt_credential(config),
                SenderIdentifierType: "4",
                ReceiverIdentifierType: "4",
                Amount: amount,
                PartyA: short_code,
                PartyB: receiver_shortcode,
                AccountReference: account_reference,
                CommandID: command_id,
                Remarks: opts[:remarks] || "B2B Payment",
                QueueTimeOutURL: config.extras[:timeout_url],
                ResultURL: config.extras[:result_url]
              }.compact

              response = connection.post(ENDPOINT, payload.to_json, headers)
              build_response(response)
            end

            private

            def build_response(response)
              parsed = response.body

              Payments::Response.new(
                provider: :mpesa,
                operation: :b2b,
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
