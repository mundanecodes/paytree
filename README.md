## STK Push

Initiate an M-Pesa STK Push (Lipa na M-Pesa Online) request.

### Configure once

```ruby
Payments.configure(:mpesa, Payments::Configs::Mpesa) do |config|
  config[:key]       = "YOUR_CONSUMER_KEY"
  config[:secret]    = "YOUR_CONSUMER_SECRET"
  config[:shortcode] = "600999"
  config[:passkey]   = "YOUR_PASSKEY"
  config[:sandbox]   = true

  # Optional extras
  config[:extras] = {
    callback_url: "https://your-app.com/mpesa/callback"
  }

  # Optional: Hook into payment events (applies to all M-Pesa operations)
  config[:on_success] = [
    ->(context) { Rails.logger.info "Payment succeeded: #{context[:context]}" },
    ->(context) { MetricsCollector.increment("payment.success.#{context[:provider]}") }
  ]

  config[:on_error] = [
    ->(context) { Rails.logger.error "Payment failed: #{context[:payload].message}" },
    ->(context) { AlertService.notify("Payment Error", context[:payload]) }
  ]
end
```

#### Initiate Push
```ruby
response = Payments::Mpesa::StkPush.call(
  phone_number: "+254712345678",
  amount: 100,
  reference: "INV-001"
)

if response.success?
  puts "STK Push initiated: #{response.data["CustomerMessage"]}"
else
  puts "Failed to initiate STK Push: #{response.message}"
end
```

## STK Query

Query the status of a previously initiated STK Push.

### Example

```ruby
response = Payments::Mpesa::StkQuery.call(
  checkout_request_id: "ws_CO_123456789"
)

if response.success?
  puts "Query successful: #{response.data["ResultDesc"]}"
else
  puts "STK Query failed: #{response.message}"
end
```

## Initiate B2C Payment

Send funds directly to a customer’s M-Pesa wallet via the B2C API.

### Example
```ruby
response = Payments::Mpesa::B2C.call(
  phone_number: "+254712345678",
  amount: 100,
  reference: "SALAARY2023JULY",
  remarks: "Monthly salary",
  occasion: "Payout",
  command_id: "BusinessPayment" # optional – defaults to "BusinessPayment"
)

if response.success?
  puts "B2C payment initiated: #{response.data["ConversationID"]}"
else
  puts "Failed to initiate B2C payment: #{response.message}"
end
```

## C2B (Customer -> Business)

### 1  Register Validation & Confirmation URLs

```ruby
Payments::Mpesa::C2B.register_urls(
  short_code:       Payments[:mpesa].shortcode,
  confirmation_url: "https://your-app.com/mpesa/confirm",
  validation_url:   "https://your-app.com/mpesa/validate"
)

response = Payments::Mpesa::C2B.simulate(
  phone_number: "+254712345678",
  amount: 75,
  reference: "INV-42"
)

if response.success?
  puts "Simulation OK: #{response.data["CustomerMessage"]}"
else
  puts "Simulation failed: #{response.message}"
end
```

## Hook System

The payment system provides hooks for monitoring and reacting to payment events. Hooks receive rich context including event type, payload, provider, timestamp, and custom metadata.

### Available Hook Context

```ruby
{
  event_type: :success,          # :success or :error
  payload: response_object,      # Result or error object
  context: "stk_push",           # Operation type that triggered the hook
  provider: :mpesa,              # Payment provider
  timestamp: Time.now,           # Execution time
  # ... any additional metadata
}
```

The `context` field indicates which payment operation triggered the hook:
- `"stk_push"`     - STK Push payment
- `"stk_query"`    - STK Query status check
- `"b2c"`          - Business to Customer payment
- `"b2b"`          - Business to Business payment
- `"c2b_register"` - C2B URL registration
- `"c2b_simulate"` - C2B payment simulation

### Hook Features

- **Error Isolation**: Hook failures don't break payment flow
- **Multiple Hooks**: Support for chaining multiple handlers per event
- **Safe Execution**: Failed hooks are logged but don't interrupt operations
- **Rich Context**: Comprehensive event information for monitoring and analytics

## B2B Payment

Send funds from one PayBill or BuyGoods shortcode to another.

### Example

```ruby
response = Payments::Mpesa::B2B.call(
  short_code: "600999",                # Sender shortcode
  receiver_shortcode: "600111",        # Receiver shortcode
  amount: 1500,
  account_reference: "UTIL-APRIL",     # Appears in recipient's statement

  # Optional
  remarks: "Utility Settlement",
  command_id: "BusinessPayBill"        # or "BusinessBuyGoods"
)

if response.success?
  puts "B2B payment accepted: #{response.message}"
else
  puts "B2B failed: #{response.message}"
end
```
