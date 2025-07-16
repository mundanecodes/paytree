RSpec.describe Payments::Utils::ErrorHandling do
  let(:test_class) do
    Class.new do
      include Payments::Utils::ErrorHandling
    end
  end

  let(:instance) { test_class.new }
  let(:mock_config) { double("config") }
  let(:mock_logger) { double("logger", error: nil, warn: nil) }

  before do
    allow(Payments).to receive(:[]).with(:mpesa).and_return(mock_config)
    allow(mock_config).to receive(:respond_to?).with(:logger).and_return(true)
    allow(mock_config).to receive(:logger).and_return(mock_logger)
  end

  describe "#trigger_success" do
    context "with single success hook" do
      it "executes the hook with proper context" do
        hook_called = false
        hook_context = nil

        hook = ->(ctx) do
          hook_called = true
          hook_context = ctx
        end

        allow(mock_config).to receive(:respond_to?).with(:on_success).and_return(true)
        allow(mock_config).to receive(:on_success).and_return(hook)

        result = {message: "Payment successful"}
        instance.send(:trigger_success, result, "stk_push", custom_data: "test")

        expect(hook_called).to be true
        expect(hook_context[:event_type]).to eq(:success)
        expect(hook_context[:payload]).to eq(result)
        expect(hook_context[:context]).to eq("stk_push")
        expect(hook_context[:provider]).to eq(:mpesa)
        expect(hook_context[:custom_data]).to eq("test")
        expect(hook_context[:timestamp]).to be_a(Time)
      end
    end

    context "with multiple success hooks" do
      it "executes all hooks in order" do
        call_order = []

        hook1 = ->(ctx) { call_order << "hook1" }
        hook2 = ->(ctx) { call_order << "hook2" }

        allow(mock_config).to receive(:respond_to?).with(:on_success).and_return(true)
        allow(mock_config).to receive(:on_success).and_return([hook1, hook2])

        result = {message: "Payment successful"}
        instance.send(:trigger_success, result, "stk_push")

        expect(call_order).to eq(["hook1", "hook2"])
      end
    end

    context "when config doesn't support on_success" do
      it "returns early without error" do
        allow(mock_config).to receive(:respond_to?).with(:on_success).and_return(false)

        expect do
          instance.send(:trigger_success, {}, "stk_push")
        end.not_to raise_error
      end
    end

    context "when hook fails" do
      it "logs the error but doesn't raise" do
        failing_hook = ->(ctx) { raise StandardError, "Hook failed" }

        allow(mock_config).to receive(:respond_to?).with(:on_success).and_return(true)
        allow(mock_config).to receive(:on_success).and_return(failing_hook)

        expect(mock_logger).to receive(:warn).with(/Hook execution failed for success: Hook failed/)

        expect do
          instance.send(:trigger_success, {}, "stk_push")
        end.not_to raise_error
      end
    end
  end

  describe "#emit_error" do
    let(:test_error) { StandardError.new("Test error") }

    context "with single error hook" do
      it "executes the hook with proper context" do
        hook_called = false
        hook_context = nil

        hook = ->(ctx) do
          hook_called = true
          hook_context = ctx
        end

        allow(mock_config).to receive(:respond_to?).with(:on_error).and_return(true)
        allow(mock_config).to receive(:on_error).and_return(hook)

        instance.send(:emit_error, test_error, "stk_push", transaction_id: "12345")

        expect(hook_called).to be true
        expect(hook_context[:event_type]).to eq(:error)
        expect(hook_context[:payload]).to eq(test_error)
        expect(hook_context[:context]).to eq("stk_push")
        expect(hook_context[:provider]).to eq(:mpesa)
        expect(hook_context[:transaction_id]).to eq("12345")
        expect(hook_context[:timestamp]).to be_a(Time)
      end
    end

    context "with multiple error hooks" do
      it "executes all hooks even if one fails" do
        call_order = []

        hook1 = ->(ctx) { call_order << "hook1" }
        failing_hook = ->(ctx) { raise "Hook2 failed" }
        hook3 = ->(ctx) { call_order << "hook3" }

        allow(mock_config).to receive(:respond_to?).with(:on_error).and_return(true)
        allow(mock_config).to receive(:on_error).and_return([hook1, failing_hook, hook3])

        expect(mock_logger).to receive(:warn).with(/Hook execution failed for error: Hook2 failed/)

        instance.send(:emit_error, test_error, "stk_push")

        expect(call_order).to eq(["hook1", "hook3"])
      end
    end

    context "when config doesn't support on_error" do
      it "only logs the error without calling hooks" do
        allow(mock_config).to receive(:respond_to?).with(:on_error).and_return(false)

        expect(mock_logger).to receive(:error)

        expect do
          instance.send(:emit_error, test_error, "stk_push")
        end.not_to raise_error
      end
    end
  end

  describe "#build_hook_context" do
    it "builds proper context structure" do
      payload = {data: "test"}
      metadata = {custom: "value", user_id: 123}

      context = instance.send(:build_hook_context, payload, "stk_push", metadata, :success)

      expect(context[:event_type]).to eq(:success)
      expect(context[:payload]).to eq(payload)
      expect(context[:context]).to eq("stk_push")
      expect(context[:provider]).to eq(:mpesa)
      expect(context[:timestamp]).to be_a(Time)
      expect(context[:custom]).to eq("value")
      expect(context[:user_id]).to eq(123)
    end
  end

  describe "#safe_execute_hook" do
    it "executes valid callable hooks" do
      executed = false
      hook = ->(ctx) { executed = true }

      hook_context = {event_type: :success, context: "test"}
      instance.send(:safe_execute_hook, hook, hook_context)

      expect(executed).to be true
    end

    it "skips non-callable hooks" do
      hook_context = {event_type: :success, context: "test"}

      expect do
        instance.send(:safe_execute_hook, "not_callable", hook_context)
      end.not_to raise_error
    end

    it "logs errors from failing hooks" do
      hook = ->(ctx) { raise "Hook error" }
      hook_context = {event_type: :success, context: "test"}

      expect(mock_logger).to receive(:warn).with(/Hook execution failed for success: Hook error/)

      instance.send(:safe_execute_hook, hook, hook_context)
    end
  end

  describe "provider extraction" do
    context "when context contains mpesa" do
      it "extracts mpesa as provider" do
        context = instance.send(:build_hook_context, {}, "mpesa_stk_push", {}, :success)
        expect(context[:provider]).to eq(:mpesa)
      end
    end

    context "when context doesn't specify provider" do
      it "defaults to mpesa" do
        context = instance.send(:build_hook_context, {}, "generic_payment", {}, :success)
        expect(context[:provider]).to eq(:mpesa)
      end
    end
  end
end
