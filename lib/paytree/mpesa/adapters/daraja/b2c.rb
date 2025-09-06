require "paytree/mpesa/adapters/daraja/base"

module Paytree
  module Mpesa
    module Adapters
      module Daraja
        class B2C < Base
          def self.endpoint
            "/mpesa/b2c/#{config.api_version}/paymentrequest"
          end

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
                }

                # Add OriginatorConversationID for v3
                if config.api_version == "v3"
                  payload[:OriginatorConversationID] = opts[:originator_conversation_id] || generate_conversation_id
                end

                post_to_mpesa(:b2c, endpoint, payload.compact)
              end
            end
          end
        end
      end
    end
  end
end
