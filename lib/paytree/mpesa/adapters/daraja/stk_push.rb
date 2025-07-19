require "paytree/mpesa/adapters/daraja/base"

module Paytree
  module Mpesa
    module Adapters
      module Daraja
        class StkPush < Base
          ENDPOINT = "/mpesa/stkpush/v1/processrequest"

          class << self
            def call(phone_number:, amount:, reference:)
              with_error_handling(context: :stk_push) do
                validate_for(:stk_push, phone_number:, amount:, reference:)

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

                post_to_mpesa(:stk_push, ENDPOINT, payload)
              end
            end
          end
        end
      end
    end
  end
end
