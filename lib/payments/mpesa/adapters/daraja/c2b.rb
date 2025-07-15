require "payments/mpesa/adapters/daraja/base"

module Payments
  module Mpesa
    module Adapters
      module Daraja
        class C2B < Base
          REGISTER_ENDPOINT = "/mpesa/c2b/v1/registerurl"
          SIMULATE_ENDPOINT = "/mpesa/c2b/v1/simulate"

          class << self
            def register_urls(short_code:, confirmation_url:, validation_url:)
              with_error_handling(context: :c2b_register) do
                validate_for(:c2b_register, short_code:, confirmation_url:, validation_url:)

                payload = {
                  ShortCode: short_code,
                  ResponseType: "Completed",
                  ConfirmationURL: confirmation_url,
                  ValidationURL: validation_url
                }

                response = connection.post(REGISTER_ENDPOINT, payload.to_json, headers)
                build_response(response, :c2b_register)
              end
            end

            def simulate(phone_number:, amount:, reference:)
              with_error_handling(context: :c2b_simulate) do
                config = self.config
                validate_for(:c2b_simulate, phone_number:, amount:, reference:)

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
