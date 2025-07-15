RSpec.shared_context "Mpesa config" do
  before do
    stub_request(:get, %r{/oauth/v1/generate}).to_return(
      status: 200,
      body: {access_token: "test_token", expires_in: 3600}.to_json,
      headers: {"Content-Type" => "application/json"}
    )

    Payments::Mpesa::Adapters::Daraja::Base.instance_variable_set(:@token, nil)
    Payments::Mpesa::Adapters::Daraja::Base.instance_variable_set(:@token_expiry, nil)

    Payments.configure(:mpesa, Payments::Configs::Mpesa) do |config|
      config.key = "TEST_KEY"
      config.secret = "TEST_SECRET"
      config.shortcode = "600999"
      config.passkey = "PASSKEY"
      config.adapter = Payments::Mpesa::Adapters::Daraja
      config.initiator_name = "test_initiator"
      config.initiator_password = "test_password"
      config.sandbox = true

      config.extras = {
        cert_path: File.join(__dir__, "../../payments/mpesa/certs/test.cer"),
        timeout_url: "https://example.com/timeout",
        result_url: "https://example.com/result"
      }

      config.logger = Logger.new($stdout) # optional
    end
  end
end
