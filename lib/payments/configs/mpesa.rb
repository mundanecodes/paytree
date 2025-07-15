require "logger"

module Payments
  module Configs
    class Mpesa
      attr_accessor :key, :secret, :shortcode, :passkey, :adapter,
        :initiator_name, :initiator_password, :sandbox,
        :extras, :on_success, :on_error

      def initialize
        @extras = {}
      end

      def base_url
        sandbox ? "https://sandbox.safaricom.co.ke" : "https://api.safaricom.co.ke"
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      attr_writer :logger
    end
  end
end
