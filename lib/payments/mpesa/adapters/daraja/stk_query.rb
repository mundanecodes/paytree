require "payments/mpesa/adapters/daraja/base"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class StkQuery < Base
          ENDPOINT = "/mpesa/stkpushquery/v1/query"

          class << self
            def call(checkout_request_id:)
              with_error_handling(context: :stk_query) do
                config = self.config

                timestamp = Time.now.strftime("%Y%m%d%H%M%S")
                password = Base64.strict_encode64("#{config.shortcode}#{config.passkey}#{timestamp}")

                payload = {
                  BusinessShortCode: config.shortcode,
                  Password: password,
                  Timestamp: timestamp,
                  CheckoutRequestID: checkout_request_id
                }

                response = connection.post(ENDPOINT, payload.to_json, headers)
                build_response(response)
              end
            end

            private

            def build_response(response)
              parsed = response.body

              Payments::Response.new(
                provider: :mpesa,
                operation: :stk_query,
                status: response.success? ? :success : :error,
                message: parsed["ResultDesc"] || parsed["errorMessage"],
                code: parsed["ResultCode"] || parsed["errorCode"],
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
