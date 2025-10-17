require "logger"

module Paytree
  module Configs
    class Mpesa
      attr_writer :logger
      attr_accessor :key, :secret, :shortcode, :passkey, :adapter,
        :initiator_name, :initiator_password, :sandbox,
        :extras, :timeout, :retryable_errors, :api_version

      def initialize
        @extras = {}
        @logger = nil
        @timeout = 30      # Default 30 second timeout
        @retryable_errors = []  # Default empty array
        @api_version = "v1"     # Default to v1 for backward compatibility
      end

      def base_url
        sandbox ? "https://sandbox.safaricom.co.ke" : "https://api.safaricom.co.ke"
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
