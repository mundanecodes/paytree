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

                post_to_mpesa(:stk_query, ENDPOINT, payload)
              end
            end
          end
        end
      end
    end
  end
end
