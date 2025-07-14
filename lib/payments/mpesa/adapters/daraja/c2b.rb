module Payments
  module Mpesa
    module Adapters
      module Daraja
        class C2B < Base
          REGISTER_ENDPOINT = "/mpesa/c2b/v1/registerurl"
          SIMULATE_ENDPOINT = "/mpesa/c2b/v1/simulate"

          class << self
            def register_urls(short_code:, confirmation_url:, validation_url:)
              unless [confirmation_url, validation_url].all?
                raise ArgumentError, "Both confirmation_url and validation_url are required"
              end

              payload = {
                ShortCode: short_code,
                ResponseType: "Completed",
                ConfirmationURL: confirmation_url,
                ValidationURL: validation_url
              }

              response = connection.post(REGISTER_ENDPOINT, payload.to_json, headers)
              build_response(response, :c2b_register)
            end

            def simulate(phone_number:, amount:, reference:)
              config = Payments[:mpesa]

              payload = {
                ShortCode: config.shortcode,
                CommandID: "CustomerPayBillOnline",
                Amount: amount,
                Msisdn: phone_number,
                BillRefNumber: reference
              }

              response = connection.post(SIMULATE_ENDPOINT, payload.to_json, headers)
              build_response(response, :c2b_simulate)
            end

            private

            def build_response(response, operation)
              parsed = response.body

              Payments::Response.new(
                provider: :mpesa,
                operation:,
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
