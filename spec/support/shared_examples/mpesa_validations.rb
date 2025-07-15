RSpec.shared_examples "a valid mpesa phone_number" do
  it "raises ValidationError when phone_number is blank" do
    expect {
      described_class.call(phone_number: "", amount: 100)
    }.to raise_error(Payments::Errors::ValidationError, /phone_number must be a valid Kenyan format/)
  end

  it "raises ValidationError when phone_number is nil" do
    expect {
      described_class.call(phone_number: nil, amount: 100)
    }.to raise_error(Payments::Errors::ValidationError, /phone_number must be a valid Kenyan format/)
  end

  it "raises ValidationError when phone_number is invalid format" do
    expect {
      described_class.call(phone_number: "0712345678", amount: 100)
    }.to raise_error(Payments::Errors::ValidationError, /phone_number must be a valid Kenyan format/)
  end

  it "raises ValidationError when phone_number is too short" do
    expect {
      described_class.call(phone_number: "25471234567", amount: 100)
    }.to raise_error(Payments::Errors::ValidationError, /phone_number must be a valid Kenyan format/)
  end

  it "raises ValidationError when phone_number is too long" do
    expect {
      described_class.call(phone_number: "2547123456789", amount: 100)
    }.to raise_error(Payments::Errors::ValidationError, /phone_number must be a valid Kenyan format/)
  end

  it "accepts valid phone_number format" do
    stub_request(:post, %r{/b2c/v1/paymentrequest}).to_return(
      status: 200,
      body: {
        ResponseDescription: "Accepted"
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    )

    expect {
      described_class.call(phone_number: "254712345678", amount: 100)
    }.not_to raise_error
  end
end

RSpec.shared_examples "a valid mpesa amount" do
  it "raises ValidationError when amount is zero" do
    expect {
      described_class.call(phone_number: "254712345678", amount: 0)
    }.to raise_error(Payments::Errors::ValidationError, /amount must be a positive number/)
  end

  it "raises ValidationError when amount is negative" do
    expect {
      described_class.call(phone_number: "254712345678", amount: -10)
    }.to raise_error(Payments::Errors::ValidationError, /amount must be a positive number/)
  end

  it "raises ValidationError when amount is not numeric" do
    expect {
      described_class.call(phone_number: "254712345678", amount: "invalid")
    }.to raise_error(Payments::Errors::ValidationError, /amount must be a positive number/)
  end
end
