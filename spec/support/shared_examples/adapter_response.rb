RSpec.shared_examples "a successful response" do |operation_key, id_key: nil|
  it { expect(subject).to be_a(Payments::Response) }
  it { expect(subject).to be_success }
  it { expect(subject.operation).to eq(operation_key) }

  if id_key
    it { expect(subject.data[id_key]).not_to be_nil }
  end
end
