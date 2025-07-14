module Payments
  module Configs
    Mpesa = Data.define(
      :key,
      :secret,
      :shortcode,
      :passkey,
      :adapter,
      :initiator_name,
      :initiator_password,
      :sandbox,       # true/false for environment
      :extras         # optional hash for additional settings
    ) do
      def base_url
        sandbox ? "https://sandbox.safaricom.co.ke" : "https://api.safaricom.co.ke"
      end
    end
  end
end
