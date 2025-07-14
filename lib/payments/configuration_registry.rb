module Payments
  # Immutable registry that stores per-provider configuration objects.
  # Each provider owns its own Data.define struct (see Payments::Configs::Mpesa).
  #
  # Usage:
  #   Payments.configure(:mpesa, Payments::Configs::Mpesa) do |config|
  #     config[:key]       = "abc"
  #     config[:secret]    = "xyz"
  #     config[:sandbox]   = true
  #   end
  #
  #   Payments[:mpesa]        #=> <#Payments::Configs::Mpesa ...>
  #   Payments[:mpesa].key    #=> "abc"
  #
  class ConfigurationRegistry
    def initialize
      @configs = {}
    end

    # Configure a provider.
    # @param provider [Symbol] e.g. :mpesa, :airtel
    # @param config_class [Class] Data.define struct for that provider
    # @yieldparam hash [Hash] mutable attributes for convenience
    # @return [Data] frozen provider config instance

    def configure(provider, config_class)
      raise ArgumentError, "config_class must be a Class" unless config_class.is_a?(Class)

      current = @configs[provider] || config_class.new(**defaults_for(config_class))
      attrs = current.to_h

      yield attrs if block_given?

      @configs[provider] = config_class.new(**attrs)
    end

    # Fetch provider config or raise if not registered.
    def [](provider)
      @configs.fetch(provider) do
        raise ArgumentError, "No config registered for provider: #{provider}"
      end
    end

    # Hash-like enumeration support (for specs/debugging)
    def to_h
      @configs.dup
    end

    private

    # Build a defaults hash with nil values for every member of the Data struct.
    def defaults_for(config_class)
      result = {}
      config_class.members.each { |key| result[key] = nil } # TODO: migrate to use _it_ from Ruby 3.4.x
      result
    end
  end
end
