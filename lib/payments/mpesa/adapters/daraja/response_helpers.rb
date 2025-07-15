module Payments
  module Mpesa
    module Adapters
      module Daraja
        module ResponseHelpers
          def build_response(response, operation)
            parsed = response.body

            Payments::Response.new(
              provider: :mpesa,
              operation:,
              status: response.success? ? :success : :error,
              message: response_message(parsed),
              code: response_code(parsed),
              data: parsed,
              raw_response: response
            )
          end

          private

          def response_message(parsed)
            parsed["ResponseDescription"] ||
              parsed["ResultDesc"] ||
              parsed["errorMessage"]
          end

          def response_code(parsed)
            parsed["ResponseCode"] ||
              parsed["ResultCode"] ||
              parsed["errorCode"]
          end
        end
      end
    end
  end
end
