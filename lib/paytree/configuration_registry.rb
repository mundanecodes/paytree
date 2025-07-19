module Paytree
  class ConfigurationRegistry
    def initialize
      @configs = {}
      @mutex = Mutex.new
    end

    def configure(provider, config_class)
      raise ArgumentError, "config_class must be a Class" unless config_class.is_a?(Class)

      config = config_class.new
      yield config if block_given?

      @mutex.synchronize do
        @configs[provider] = config
      end
    end

    def store_config(provider, config_instance)
      @mutex.synchronize do
        @configs[provider] = config_instance
      end
    end

    def [](provider)
      @mutex.synchronize do
        @configs.fetch(provider) do
          raise ArgumentError, "No config registered for provider: #{provider}"
        end
      end
    end

    def to_h
      @mutex.synchronize do
        @configs.dup
      end
    end
  end
end
