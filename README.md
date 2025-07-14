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
