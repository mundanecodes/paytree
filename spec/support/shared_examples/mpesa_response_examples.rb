RSpec.shared_examples "a successful response" do |operation_key, id_key: nil|
  it { expect(subject).to be_a(Paytree::Response) }
  it { expect(subject).to be_success }
  it { expect(subject.operation).to eq(operation_key) }

  if id_key
    it { expect(subject.data[id_key]).not_to be_nil }
  end
end

RSpec.shared_examples "a successful mpesa payment" do
  it "returns a success response" do
    expect(subject).to be_success
    expect(subject.data["ResponseDescription"]).to match(/Accept/)
  end
end

RSpec.shared_examples "a failed mpesa API call" do
  it "marks the response as error" do
    expect(subject).to be_error
    expect(subject.message).to eq("Invalid initiator credentials")
  end
end

RSpec.shared_examples "malformed mpesa response" do
  it "raises Paytree::Errors::MpesaMalformedResponse" do
    expect {
      subject
    }.to raise_error(Paytree::Errors::MpesaMalformedResponse)
  end
end

RSpec.shared_examples "mpesa certificate validation" do
  it "raises Paytree::Errors::MpesaCertMissing" do
    expect {
      subject
    }.to raise_error(Paytree::Errors::MpesaCertMissing, /Missing or unreadable certificate/)
  end
end

RSpec.shared_examples "mpesa config validation" do |missing_key|
  it "raises Paytree::Errors::ConfigurationError" do
    expect {
      subject
    }.to raise_error(Paytree::Errors::ConfigurationError, /#{missing_key}/)
  end
end
