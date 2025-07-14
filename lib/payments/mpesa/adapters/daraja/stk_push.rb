require "payments/mpesa/adapters/daraja/base"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class StkPush < Base
          ENDPOINT = "/mpesa/stkpush/v1/processrequest"

          class << self
            def call(phone_number:, amount:, reference:)
              config = Payments[:mpesa]
              timestamp = Time.now.strftime("%Y%m%d%H%M%S")
              password = Base64.strict_encode64("#{config.shortcode}#{config.passkey}#{timestamp}")

              payload = {
                BusinessShortCode: config.shortcode,
                Password: password,
                Timestamp: timestamp,
                TransactionType: "CustomerPayBillOnline",
                Amount: amount,
                PartyA: phone_number,
                PartyB: config.shortcode,
                PhoneNumber: phone_number,
                CallBackURL: config.extras[:callback_url],
                AccountReference: reference,
                TransactionDesc: reference
              }

              response = connection.post(ENDPOINT, payload.to_json, headers)
              build_response(response)
            end

            private

            def build_response(response)
              parsed = response.body

              Payments::Response.new(
                provider: :mpesa,
                operation: :stk_push,
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
