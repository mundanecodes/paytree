require "spec_helper"
require "payments/response"

RSpec.describe Payments::Response do
  let(:response) do
    described_class.new(
      provider: :mpesa,
      operation: :stk_push,
      status: :success,
      message: "Request accepted",
      code: "0",
      data: {checkout_request_id: "abc123"},
      raw_response: double("Faraday::Response", status: 200)
    )
  end

  it "returns success? as true when status is :success" do
    expect(response.success?).to be true
  end

  it "returns error? as false when status is :success" do
    expect(response.error?).to be false
  end

  it "serializes to a hash correctly" do
    expect(response.to_h).to eq({
      provider: :mpesa,
      operation: :stk_push,
      status: :success,
      message: "Request accepted",
      code: "0",
      data: {checkout_request_id: "abc123"}
    })
  end

  it "exposes raw_response for debugging or inspection" do
    expect(response.raw_response.status).to eq 200
  end
end
