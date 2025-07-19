require "paytree/mpesa/adapters/daraja/base"

module Paytree
  module Mpesa
    module Adapters
      module Daraja
        class B2B < Base
          ENDPOINT = "/mpesa/b2b/v1/paymentrequest"

          class << self
            def call(short_code:, receiver_shortcode:, amount:, account_reference:, **opts)
              with_error_handling(context: :b2b) do
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

                post_to_mpesa(:b2b, ENDPOINT, payload)
              end
            end
          end
        end
      end
    end
  end
end
