require "spec_helper"

RSpec.describe "Simplified M-Pesa Configuration" do
  before do
    # Clear any existing configuration
    Paytree.instance_variable_set(:@registry, nil)
  end

  describe ".configure_mpesa" do
    it "configures M-Pesa with hash arguments" do
      Paytree.configure_mpesa(
        key: "test_key",
        secret: "test_secret",
        shortcode: "600999",
        passkey: "test_passkey",
        sandbox: false
      )

      config = Paytree[:mpesa]
      expect(config.key).to eq("test_key")
      expect(config.secret).to eq("test_secret")
      expect(config.shortcode).to eq("600999")
      expect(config.passkey).to eq("test_passkey")
      expect(config.sandbox).to be false
    end

    it "handles extras configuration" do
      Paytree.configure_mpesa(
        key: "test_key",
        secret: "test_secret",
        extras: {
          callback_url: "https://example.com/callback",
          result_url: "https://example.com/result"
        }
      )

      config = Paytree[:mpesa]
      expect(config.extras[:callback_url]).to eq("https://example.com/callback")
      expect(config.extras[:result_url]).to eq("https://example.com/result")
    end

    it "handles hook configuration" do
      success_hook = ->(ctx) { puts "Success!" }
      error_hook = ->(ctx) { puts "Error!" }

      Paytree.configure_mpesa(
        key: "test_key",
        secret: "test_secret",
        on_success: [success_hook],
        on_error: [error_hook]
      )

      config = Paytree[:mpesa]
      expect(config.on_success).to eq([success_hook])
      expect(config.on_error).to eq([error_hook])
    end

    it "sets sandbox default to true when not specified" do
      Paytree.configure_mpesa(
        key: "test_key",
        secret: "test_secret"
      )

      config = Paytree[:mpesa]
      expect(config.sandbox).to be true
    end

    it "respects explicit sandbox setting" do
      Paytree.configure_mpesa(
        key: "test_key",
        secret: "test_secret",
        sandbox: false
      )

      config = Paytree[:mpesa]
      expect(config.sandbox).to be false
    end
  end

  describe ".configure_mpesa_sandbox" do
    it "sets sandbox to true and default shortcode" do
      Paytree.configure_mpesa_sandbox(
        key: "test_key",
        secret: "test_secret",
        passkey: "test_passkey"
      )

      config = Paytree[:mpesa]
      expect(config.sandbox).to be true
      expect(config.shortcode).to eq("174379")
      expect(config.key).to eq("test_key")
    end

    it "allows overriding defaults" do
      Paytree.configure_mpesa_sandbox(
        key: "test_key",
        secret: "test_secret",
        shortcode: "custom_shortcode"
      )

      config = Paytree[:mpesa]
      expect(config.sandbox).to be true
      expect(config.shortcode).to eq("custom_shortcode")
    end
  end

  describe ".configure_mpesa_production" do
    it "sets sandbox to false" do
      Paytree.configure_mpesa_production(
        key: "test_key",
        secret: "test_secret",
        shortcode: "600999"
      )

      config = Paytree[:mpesa]
      expect(config.sandbox).to be false
      expect(config.shortcode).to eq("600999")
    end
  end

  describe ".auto_configure_mpesa!" do
    before do
      # Clear environment more thoroughly
      %w[MPESA_CONSUMER_KEY MPESA_CONSUMER_SECRET MPESA_SHORTCODE MPESA_PASSKEY
        MPESA_SANDBOX MPESA_CALLBACK_URL MPESA_RESULT_URL MPESA_TIMEOUT_URL
        MPESA_INITIATOR_NAME MPESA_INITIATOR_PASSWORD].each do |var|
        ENV.delete(var)
      end
    end

    after do
      # Clean up environment
      %w[MPESA_CONSUMER_KEY MPESA_CONSUMER_SECRET MPESA_SHORTCODE MPESA_PASSKEY
        MPESA_SANDBOX MPESA_CALLBACK_URL MPESA_RESULT_URL MPESA_TIMEOUT_URL
        MPESA_INITIATOR_NAME MPESA_INITIATOR_PASSWORD].each do |var|
        ENV.delete(var)
      end
    end

    it "configures from environment variables" do
      ENV["MPESA_CONSUMER_KEY"] = "env_key"
      ENV["MPESA_CONSUMER_SECRET"] = "env_secret"
      ENV["MPESA_SHORTCODE"] = "env_shortcode"
      ENV["MPESA_PASSKEY"] = "env_passkey"
      ENV["MPESA_SANDBOX"] = "false"

      Paytree.auto_configure_mpesa!

      config = Paytree[:mpesa]
      expect(config.key).to eq("env_key")
      expect(config.secret).to eq("env_secret")
      expect(config.shortcode).to eq("env_shortcode")
      expect(config.passkey).to eq("env_passkey")
      expect(config.sandbox).to be false
    end

    it "handles boolean conversion for sandbox" do
      ENV["MPESA_CONSUMER_KEY"] = "key"
      ENV["MPESA_SANDBOX"] = "true"

      Paytree.auto_configure_mpesa!

      expect(Paytree[:mpesa].sandbox).to be true

      # Test other truthy values
      ENV["MPESA_SANDBOX"] = "1"
      Paytree.auto_configure_mpesa!
      expect(Paytree[:mpesa].sandbox).to be true

      ENV["MPESA_SANDBOX"] = "yes"
      Paytree.auto_configure_mpesa!
      expect(Paytree[:mpesa].sandbox).to be true

      ENV["MPESA_SANDBOX"] = "false"
      Paytree.auto_configure_mpesa!
      expect(Paytree[:mpesa].sandbox).to be false
    end

    it "loads extras from environment" do
      ENV["MPESA_CONSUMER_KEY"] = "key"
      ENV["MPESA_CALLBACK_URL"] = "https://example.com/callback"
      ENV["MPESA_RESULT_URL"] = "https://example.com/result"

      Paytree.auto_configure_mpesa!

      config = Paytree[:mpesa]
      expect(config.extras[:callback_url]).to eq("https://example.com/callback")
      expect(config.extras[:result_url]).to eq("https://example.com/result")
    end

    it "raises error when no environment variables are set" do
      expect do
        Paytree.auto_configure_mpesa!
      end.to raise_error(ArgumentError, "No M-Pesa environment variables found")
    end
  end

  describe "environment variable auto-loading in configure_mpesa" do
    before do
      # Clear all env vars first
      %w[MPESA_CONSUMER_KEY MPESA_CONSUMER_SECRET MPESA_SHORTCODE MPESA_PASSKEY
        MPESA_SANDBOX MPESA_CALLBACK_URL MPESA_RESULT_URL MPESA_TIMEOUT_URL
        MPESA_INITIATOR_NAME MPESA_INITIATOR_PASSWORD].each do |var|
        ENV.delete(var)
      end

      # Set only the ones we want
      ENV["MPESA_CONSUMER_KEY"] = "env_key"
      ENV["MPESA_CONSUMER_SECRET"] = "env_secret"
    end

    after do
      %w[MPESA_CONSUMER_KEY MPESA_CONSUMER_SECRET MPESA_SHORTCODE MPESA_PASSKEY
        MPESA_SANDBOX MPESA_CALLBACK_URL MPESA_RESULT_URL MPESA_TIMEOUT_URL
        MPESA_INITIATOR_NAME MPESA_INITIATOR_PASSWORD].each do |var|
        ENV.delete(var)
      end
    end

    it "auto-loads environment variables and allows overrides" do
      Paytree.configure_mpesa(
        shortcode: "override_shortcode",
        sandbox: false
      )

      config = Paytree[:mpesa]
      expect(config.key).to eq("env_key")          # From environment
      expect(config.secret).to eq("env_secret")    # From environment
      expect(config.shortcode).to eq("override_shortcode")  # Override
      expect(config.sandbox).to be false           # Override
    end
  end

  describe "backward compatibility" do
    it "still supports original configuration method" do
      Paytree.configure(:mpesa, Paytree::Configs::Mpesa) do |config|
        config.key = "block_key"
        config.secret = "block_secret"
        config.sandbox = true
      end

      config = Paytree[:mpesa]
      expect(config.key).to eq("block_key")
      expect(config.secret).to eq("block_secret")
      expect(config.sandbox).to be true
    end
  end
end
