module Paytree
  module Mpesa
    module Adapters
      module Daraja
        module ResponseHelpers
          def build_response(response, operation)
            # Handle ErrorResponse from HTTPX
            if response.is_a?(HTTPX::ErrorResponse)
              raise response.error if response.error
              raise HTTPX::Error, "Request failed"
            end

            parsed = response.json

            Paytree::Response.new(
              provider: :mpesa,
              operation:,
              status: successful_response?(response) ? :success : :error,
              message: response_message(parsed),
              code: response_code(parsed),
              data: parsed,
              raw_response: response
            )
          end

          private

          def successful_response?(response)
            response.status >= 200 && response.status < 300
          end

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
