<p align="center">
  <img src="https://badge.fury.io/rb/paytree.svg" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg" />
  <img src="https://img.shields.io/badge/ruby-3.2+-red" />
  <a href="https://github.com/mundanecodes/paytree/actions">
    <img src="https://github.com/mundanecodes/paytree/actions/workflows/ci.yml/badge.svg" />
  </a>
</p>

# Paytree

A simple, highly opinionated Rails-optional Ruby gem for mobile money integrations.
Currently supports Kenya's M-Pesa via the Daraja API with plans for additional providers.

## Features

- **Simple & Minimal**: Clean API with sensible defaults
- **Convention over Configuration**: One clear setup pattern, opinionated defaults
- **Safe Defaults**: Sandbox mode, proper timeouts, comprehensive error handling
- **Batteries Included**: STK Push, B2C, B2B, C2B operations out of the box
- **API Versioning**: Support for both Daraja API v1 and v3 with backward compatibility
- **Enhanced Reliability**: Automatic token retry with exponential backoff
- **Security First**: Credential management, no hardcoded secrets

## Quick Start

### 1. Installation

Add to your Gemfile:

```ruby
gem 'paytree'
```

Or install directly:

```bash
gem install paytree
```

### 2. Get M-Pesa API Credentials

1. Register at [Safaricom Developer Portal](https://developer.safaricom.co.ke/)
2. Create a new app to get your Consumer Key and Secret
3. For testing, use the sandbox environment

### 3. Basic Setup

```ruby
# For quick testing (defaults to sandbox)
Paytree.configure_mpesa(
  key: "your_consumer_key",
  secret: "your_consumer_secret",
  passkey: "your_passkey"
)

# Make your first payment request
response = Paytree::Mpesa::StkPush.call(
  phone_number: "254712345678",
  amount: 100,
  reference: "ORDER-001"
)

puts response.success? ? "Payment initiated!" : "Error: #{response.message}"
```

---

## Configuration

Paytree uses a single `configure_mpesa` method that defaults to sandbox mode for safety.

### Rails Applications (Recommended)

Create `config/initializers/paytree.rb`:

```ruby
# config/initializers/paytree.rb

# Development/Testing (defaults to sandbox)
Paytree.configure_mpesa(
  key: Rails.application.credentials.mpesa[:consumer_key],
  secret: Rails.application.credentials.mpesa[:consumer_secret],
  passkey: Rails.application.credentials.mpesa[:passkey]
)

# Production (explicitly set sandbox: false)
# Paytree.configure_mpesa(
#   key: Rails.application.credentials.mpesa[:consumer_key],
#   secret: Rails.application.credentials.mpesa[:consumer_secret],
#   shortcode: "YOUR_PRODUCTION_SHORTCODE",
#   passkey: Rails.application.credentials.mpesa[:passkey],
#   sandbox: false,
#   api_version: "v1",                                            # Optional: "v1" (default) or "v3"
#   retryable_errors: ["429.001.01", "500.001.02", "503.001.01"] # Optional: errors to retry
# )
```

---

## API Version Support

Paytree supports both M-Pesa Daraja API v1 and v3 endpoints. The API version can be configured globally or via environment variables.

### Configuration Options

```ruby
# Use v1 API (default - backward compatible)
Paytree.configure_mpesa(
  key: "YOUR_KEY",
  secret: "YOUR_SECRET",
  api_version: "v1"  # Default
)

# Use v3 API (latest features)
Paytree.configure_mpesa(
  key: "YOUR_KEY",
  secret: "YOUR_SECRET",
  api_version: "v3"
)

# Or via environment variable
ENV['MPESA_API_VERSION'] = 'v3'
Paytree.configure_mpesa(
  key: "YOUR_KEY",
  secret: "YOUR_SECRET"
  # api_version automatically picked up from ENV
)
```

### Differences Between v1 and v3

| Feature | v1 | v3 |
|---------|----|----|
| **Endpoints** | `/mpesa/b2c/v1/paymentrequest` | `/mpesa/b2c/v3/paymentrequest` |
| **OriginatorConversationID** | Not required | Auto-generated UUID |
| **Reliability** | Standard | Enhanced with better tracking |


**Backward Compatibility:**
- Existing code continues to work unchanged (defaults to v1)
- No breaking changes when upgrading Paytree versions
- Can switch between v1/v3 by changing configuration only

---

## Usage Examples

### STK Push (Customer Payment)

Initiate an M-Pesa STK Push (Lipa na M-Pesa Online) request.

#### Basic STK Push

```ruby
# Initiate payment request - customer receives prompt on their phone
response = Paytree::Mpesa::StkPush.call(
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
response = Paytree::Mpesa::StkQuery.call(
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

---

## B2C Payment (Business to Customer)

### Initiate B2C Payment

Send funds directly to a customer’s M-Pesa wallet via the B2C API.

### Basic Example
```ruby
response = Paytree::Mpesa::B2C.call(
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

### v3 API Features

When using `api_version: "v3"`, B2C calls automatically include an `OriginatorConversationID` for enhanced tracking:

```ruby
# Configure for v3 API
Paytree.configure_mpesa(
  key: "YOUR_KEY",
  secret: "YOUR_SECRET",
  api_version: "v3"
)

# Same call, but now uses v3 endpoint with auto-generated OriginatorConversationID
response = Paytree::Mpesa::B2C.call(
  phone_number: "254712345678",
  amount: 100
)

# v3 response includes additional tracking data
if response.success?
  puts "Conversation ID: #{response.data["ConversationID"]}"
  puts "Originator ID: #{response.data["OriginatorConversationID"]}" # Auto-generated UUID
end
```

### Custom OriginatorConversationID (v3 only)

You can provide your own tracking ID for v3 API calls:

```ruby
response = Paytree::Mpesa::B2C.call(
  phone_number: "254712345678",
  amount: 100,
  originator_conversation_id: "CUSTOM-TRACK-#{Time.now.to_i}"
)
```

---

## C2B (Customer to Business)

### 1  Register Validation & Confirmation URLs

```ruby
Paytree::Mpesa::C2B.register_urls(
  short_code:       Payments[:mpesa].shortcode,
  confirmation_url: "https://your-app.com/mpesa/confirm",
  validation_url:   "https://your-app.com/mpesa/validate"
)

response = Paytree::Mpesa::C2B.simulate(
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

---

## B2B Payment (Business to Business)

Send funds from one PayBill or BuyGoods shortcode to another.

### Example

```ruby
response = Paytree::Mpesa::B2B.call(
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

---

## Response Format

All Paytree operations return a consistent response object with these attributes:

### Response Attributes

```ruby
response.success?    # Boolean - true if operation succeeded
response.message     # String - human-readable message
response.data        # Hash - response data from M-Pesa API
response.code        # String - M-Pesa response code (if available)
response.retryable?  # Boolean - true if error is configured as retryable
```

### Success Response Example

```ruby
response = Paytree::Mpesa::StkPush.call(
  phone_number: "254712345678",
  amount: 100,
  reference: "ORDER-001"
)

if response.success?
  puts response.message  # "STK Push request successful"
  puts response.data     # {"MerchantRequestID"=>"29115-34620561-1", "CheckoutRequestID"=>"ws_CO_191220191020363925"...}
end
```

### Error Response Example

```ruby
unless response.success?
  puts response.message  # "Invalid Access Token"
  puts response.code     # "404.001.03" (if available)
  puts response.data     # {
                         #   "requestId" => "",
                         #   "errorCode" => "404.001.03",
                         #   "errorMessage" => "Invalid Access Token"
                         # }

  # Check if error is retryable (based on configuration)
  if response.retryable?
    puts "This error can be retried"
    # Implement your retry logic here
  else
    puts "This error should not be retried"
  end
end
```



### Common Response Data Fields

**STK Push Response:**
- `CheckoutRequestID` - Use this to query payment status
- `MerchantRequestID` - Internal M-Pesa tracking ID
- `CustomerMessage` - Message shown to customer

**STK Query Response:**
- `ResultCode` - "0" = success, "1032" = cancelled, "1037" = timeout
- `ResultDesc` - Human-readable result description
- `MpesaReceiptNumber` - M-Pesa transaction receipt (on success)
- `Amount` - Transaction amount
- `TransactionDate` - When payment was completed

**B2C/B2B Response:**
- `ConversationID` - Transaction tracking ID
- `OriginatorConversationID` - Your internal tracking ID
- `ResponseDescription` - Status message

### Retryable Errors

Paytree allows you to configure which error codes should be considered retryable. This is useful for building resilient payment systems that can automatically retry transient errors.

**Common retryable errors:**
- `"429.001.01"` - Rate limit exceeded
- `"500.001.02"` - Temporary server error
- `"503.001.01"` - Service temporarily unavailable
- `"timeout.connection"` - Network connection timeout (Net::OpenTimeout)
- `"timeout.read"` - Network read timeout (Net::ReadTimeout)
- `"timeout.request"` - HTTP request timeout (HTTPX::TimeoutError)

Configure retryable errors during setup:

```ruby
Paytree.configure_mpesa(
  key: "YOUR_KEY",
  secret: "YOUR_SECRET",
  retryable_errors: [
    "429.001.01",         # Rate limit
    "500.001.02",         # Server error  
    "503.001.01",         # Service unavailable
    "timeout.connection", # Connection timeout
    "timeout.read",       # Read timeout
    "timeout.request"     # Request timeout
  ]
)
```

Then check if an error response can be retried:

```ruby
response = Paytree::Mpesa::StkPush.call(...)

unless response.success?
  if response.retryable?
    # Implement exponential backoff retry logic
    retry_with_backoff
  else
    # Handle permanent error
    handle_permanent_failure(response)
  end
end
```

---
