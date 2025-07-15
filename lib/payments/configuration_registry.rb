module Payments
  class ConfigurationRegistry
    def initialize
      @configs = {}
    end

    def configure(provider, config_class)
      raise ArgumentError, "config_class must be a Class" unless config_class.is_a?(Class)

      config = config_class.new
      yield config if block_given?
      @configs[provider] = config
    end

    def [](provider)
      @configs.fetch(provider) do
        raise ArgumentError, "No config registered for provider: #{provider}"
      end
    end

    def to_h
      @configs.dup
    end
  end
end
