# Payments

A simple, highly opinionated Rails-optional Ruby gem for mobile money integrations. Currently supports Kenya's M-Pesa via the Daraja API with plans for additional providers.

## Features

- **Simple & Minimal**: Clean API with sensible defaults
- **Convention over Configuration**: Multiple setup patterns for different needs  
- **Safe Defaults**: Sandbox mode, proper timeouts, comprehensive error handling
- **Batteries Included**: STK Push, B2C, B2B, C2B operations out of the box
- **Security First**: Environment-based configuration, no hardcoded secrets
- **Hook System**: Built-in success/error callbacks for monitoring and analytics

## Quick Start

### 1. Installation

Add to your Gemfile:

```ruby
gem 'payments'
```

Or install directly:

```bash
gem install payments
```

### 2. Get M-Pesa API Credentials

1. Register at [Safaricom Developer Portal](https://developer.safaricom.co.ke/)
2. Create a new app to get your Consumer Key and Secret
3. For testing, use the sandbox environment

### 3. Basic Setup

```ruby
# For quick testing (uses sandbox by default)
Payments.configure_mpesa_sandbox(
  key: "your_consumer_key",
  secret: "your_consumer_secret", 
  passkey: "your_passkey"
)

# Make your first payment request
response = Payments::Mpesa::StkPush.call(
  phone_number: "254712345678",
  amount: 100,
  reference: "ORDER-001"
)

puts response.success? ? "Payment initiated!" : "Error: #{response.message}"
```

## Configuration

Choose the approach that fits your application:

### Option 1: Environment Variables (Recommended for Production)

Set these environment variables:

```bash
MPESA_CONSUMER_KEY=your_key
MPESA_CONSUMER_SECRET=your_secret
MPESA_SHORTCODE=174379
MPESA_PASSKEY=your_passkey
MPESA_SANDBOX=false
MPESA_CALLBACK_URL=https://your-app.com/mpesa/callback
```

Then in your app:

```ruby
# Auto-configure from environment
Payments.auto_configure_mpesa!
```

### Option 2: Hash Configuration

```ruby
# Hash-based configuration
Payments.configure_mpesa(
  key: "YOUR_CONSUMER_KEY",
  secret: "YOUR_CONSUMER_SECRET", 
  shortcode: "174379",
  passkey: "YOUR_PASSKEY",
  sandbox: false,  # Set to true for testing
  extras: {
    callback_url: "https://your-app.com/mpesa/callback"
  }
)
```

### Option 3: Preset Configurations

```ruby
# For development/testing
Payments.configure_mpesa_sandbox(
  key: "YOUR_CONSUMER_KEY",
  secret: "YOUR_CONSUMER_SECRET",
  passkey: "YOUR_PASSKEY"
)

# For production
Payments.configure_mpesa_production(
  key: "YOUR_CONSUMER_KEY",
  secret: "YOUR_CONSUMER_SECRET",
  shortcode: "174379",
  passkey: "YOUR_PASSKEY"
)
```

## Usage Examples

### STK Push (Customer Payment)

Initiate an M-Pesa STK Push (Lipa na M-Pesa Online) request.

#### Basic STK Push

```ruby
# Initiate payment request - customer receives prompt on their phone
response = Payments::Mpesa::StkPush.call(
  phone_number: "254712345678",  # Must be in 254XXXXXXXXX format
  amount: 100,                   # Amount in KES (Kenyan Shillings)
  reference: "ORDER-001"         # Your internal reference
)

# Handle the response
if response.success?
  puts "Payment request sent! Customer will receive STK prompt."
  puts "Checkout Request ID: #{response.data['CheckoutRequestID']}"
  
  # Store the CheckoutRequestID to query status later
  order.update(mpesa_checkout_id: response.data['CheckoutRequestID'])
else
  puts "Payment request failed: #{response.message}"
  Rails.logger.error "STK Push failed for order #{order.id}: #{response.message}"
end
```

**Important**: STK Push only initiates the payment request. The customer must complete payment on their phone. Use STK Query or webhooks to get the final status.

### STK Query (Check Payment Status)

Query the status of a previously initiated STK Push to see if the customer completed payment.

```ruby
# Check payment status using the CheckoutRequestID from STK Push
response = Payments::Mpesa::StkQuery.call(
  checkout_request_id: "ws_CO_123456789"
)

if response.success?
  result_code = response.data["ResultCode"]
  
  case result_code
  when "0"
    puts "Payment completed successfully!"
    puts "Amount: #{response.data['Amount']}"
    puts "Receipt: #{response.data['MpesaReceiptNumber']}"
    puts "Transaction Date: #{response.data['TransactionDate']}"
    
    # Update your order as paid
    order.update(status: 'paid', mpesa_receipt: response.data['MpesaReceiptNumber'])
  when "1032"
    puts "Payment cancelled by user"
  when "1037" 
    puts "Payment timed out (user didn't respond)"
  else
    puts "Payment failed: #{response.data['ResultDesc']}"
  end
else
  puts "Query failed: #{response.message}"
end
```

## Initiate B2C Payment

Send funds directly to a customer’s M-Pesa wallet via the B2C API.

### Example
```ruby
response = Payments::Mpesa::B2C.call(
  phone_number: "254712345678",
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
  phone_number: "254712345678",
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
  short_code: "174379",                # Sender shortcode (use your actual shortcode)
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
