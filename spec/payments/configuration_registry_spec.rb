require "payments"

RSpec.describe Payments::ConfigurationRegistry do
  let(:registry) { described_class.new }
  let(:mpesa_class) { Payments::Configs::Mpesa }

  # Simulate a user-defined config struct for Airtel
  let(:airtel_class) do
    Data.define(:client_id, :client_secret, :region)
  end

  it "configures Mpesa with immutable settings" do
    registry.configure(:mpesa, mpesa_class) do |config|
      config[:extras] = {}
      config[:key] = "abc"
      config[:secret] = "xyz"
      config[:sandbox] = true
      config[:shortcode] = 123456
      config[:passkey] = "passkey12345"
    end

    config = registry[:mpesa]
    expect(config.key).to eq("abc")
    expect(config.base_url).to eq("https://sandbox.safaricom.co.ke")
    expect(config.passkey).to eq("passkey12345")
  end

  it "raises if accessing an unregistered config" do
    expect { registry[:tingg] }.to raise_error(ArgumentError, /No config registered/)
  end

  it "allows adding Airtel provider dynamically" do
    registry.configure(:airtel, airtel_class) do |config|
      config[:client_id] = "aid"
      config[:client_secret] = "asecret"
      config[:region] = "ke"
    end

    airtel = registry[:airtel]
    expect(airtel.client_id).to eq("aid")
    expect(airtel.region).to eq("ke")
  end
end
