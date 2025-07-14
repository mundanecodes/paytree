require "faraday"
require "json"

require_relative "payments/version"
require_relative "payments/response"
require_relative "payments/configuration_registry"
require_relative "payments/configs/mpesa"

module Payments
  class << self
    def registry
      @registry ||= ConfigurationRegistry.new
    end

    def configure(provider, config_class = nil, &block)
      raise ArgumentError, "Missing block" unless block
      raise ArgumentError, "Missing config_class" unless config_class

      registry.configure(provider, config_class, &block)
    end

    def [](provider)
      registry[provider]
    end
  end
end
