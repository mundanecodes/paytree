require "payments"

RSpec.describe Payments::ConfigurationRegistry do
  let(:registry) { described_class.new }

  let(:mpesa_class) do
    Data.define(:key, :secret, :sandbox, :shortcode, :passkey, :extras) do
      def base_url
        sandbox ? "sandbox.url" : "prod.url"
      end
    end
  end

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
    expect(config.base_url).to eq("sandbox.url")
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
