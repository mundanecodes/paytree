module Payments
  module Configs
    Mpesa = Data.define(
      :key,
      :secret,
      :shortcode,
      :passkey,
      :sandbox,      # true/false for environment
      :extras         # optional hash for additional settings
    ) do
      def base_url
        sandbox ? "https://sandbox.safaricom.co.ke" : "https://api.safaricom.co.ke"
      end
    end

    # To add another provider (e.g., Airtel):
    #
    # Airtel = Data.define(
    #   :key,
    #   :secret,
    #   :callback_url,
    #   :sandbox,
    #   :extras
    # ) do
    #   def base_url
    #     sandbox ? "https://sandbox.airtel.com" : "https://api.airtel.com"
    #   end
    # end
  end
end
