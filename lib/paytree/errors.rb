module Paytree
  module Errors
    Base = Class.new(StandardError)

    MpesaCertMissing = Class.new(Base)
    MpesaTokenError = Class.new(Base)
    MpesaMalformedResponse = Class.new(Base)
    MpesaResponseError = Class.new(Base)
    MpesaClientError = Class.new(Base)
    MpesaServerError = Class.new(Base)
    MpesaHttpError = Class.new(Base)

    ConfigurationError = Class.new(Base)
    UnsupportedOperation = Class.new(Base)
    ValidationError = Class.new(Base)
  end
end
