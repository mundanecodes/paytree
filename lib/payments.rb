require "json"
require "faraday"

Dir[File.join(__dir__, "payments/**/*.rb")].sort.each { |file| require file }

module Payments
  class << self
    def registry
      @registry ||= ConfigurationRegistry.new
    end

    def configure(provider, config_class = nil)
      raise ArgumentError, "Missing block" unless block_given?
      raise ArgumentError, "Missing config_class" unless config_class

      registry.configure(provider, config_class) { |hash| yield hash }
    end

    def [](provider)
      registry[provider]
    end
  end
end
