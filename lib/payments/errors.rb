module Payments
  module Errors
    Base = Class.new(StandardError)

    # M-Pesa-specific errors
    MpesaCertMissing = Class.new(Base)
    MpesaTokenError = Class.new(Base)
    MpesaMalformedResponse = Class.new(Base)
    MpesaResponseError = Class.new(Base)

    # General config / validation
    ConfigurationError = Class.new(Base)
    UnsupportedOperation = Class.new(Base)
    ValidationError = Class.new(Base)
  end
end
