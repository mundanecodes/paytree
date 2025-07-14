RSpec.shared_examples "a successful STK Push" do
  it { expect(subject).to be_a(Payments::Response) }
  it { expect(subject).to be_success }
  it { expect(subject.data["CheckoutRequestID"]).to eq("ws_CO_123456789") }
end
