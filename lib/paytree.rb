require "json"
require "faraday"

Dir[File.join(__dir__, "paytree/**/*.rb")].sort.each { |file| require file }

module Paytree
  class << self
    def registry
      @registry ||= ConfigurationRegistry.new
    end

    def configure(provider, config_class = nil)
      raise ArgumentError, "Missing block" unless block_given?
      raise ArgumentError, "Missing config_class" unless config_class

      registry.configure(provider, config_class) { |hash| yield hash }
    end

    def configure_mpesa(**options)
      config = Configs::Mpesa.new

      # Auto-load from environment variables if not provided
      options = auto_load_env_vars.merge(options)

      # Set configuration values
      options.each do |key, value|
        if config.respond_to?("#{key}=")
          config.send("#{key}=", value)
        elsif key == :extras
          config.extras.merge!(value)
        end
      end

      # Set smart defaults
      config.sandbox = true if config.sandbox.nil?

      registry.store_config(:mpesa, config)
    end

    def [](provider)
      registry[provider]
    end

    private

    def auto_load_env_vars
      env_mapping = {
        key: "MPESA_CONSUMER_KEY",
        secret: "MPESA_CONSUMER_SECRET",
        shortcode: "MPESA_SHORTCODE",
        passkey: "MPESA_PASSKEY",
        initiator_name: "MPESA_INITIATOR_NAME",
        initiator_password: "MPESA_INITIATOR_PASSWORD",
        sandbox: "MPESA_SANDBOX",
        api_version: "MPESA_API_VERSION"
      }

      config = {}
      env_mapping.each do |config_key, env_var|
        value = ENV[env_var]
        next unless value

        # Convert sandbox to boolean
        if config_key == :sandbox
          value = %w[true 1 yes].include?(value.downcase)
        end

        config[config_key] = value
      end

      # Load extras from environment
      extras = {}
      %w[callback_url result_url timeout_url].each do |extra|
        env_var = "MPESA_#{extra.upcase}"
        extras[extra.to_sym] = ENV[env_var] if ENV[env_var]
      end

      config[:extras] = extras unless extras.empty?

      config
    end
  end
end
