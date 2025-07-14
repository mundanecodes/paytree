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
      config[:key] = "TEST_KEY"
      config[:secret] = "TEST_SECRET"
      config[:shortcode] = "600999"
      config[:passkey] = "PASSKEY"
      config[:sandbox] = true

      config[:initiator_name] = "test_initiator"
      config[:initiator_password] = "test_password"

      config[:extras] = {
        cert_path: File.expand_path("spec/payments/mpesa/certs/test.cer", Dir.pwd),
        timeout_url: "https://example.com/mpesa/timeout",
        result_url: "https://example.com/mpesa/result"
      }

      config[:adapter] = Payments::Mpesa::Adapters::Daraja
    end
  end
end
