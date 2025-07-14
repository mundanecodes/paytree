module Payments
  class Response
    attr_reader :provider, :operation, :status, :message, :code, :data, :raw_response

    def initialize(provider:, operation:, status:, message:, code:, data:, raw_response:)
      @provider = provider
      @operation = operation
      @status = status
      @message = message
      @code = code
      @data = data
      @raw_response = raw_response
    end

    def success?
      status == :success
    end

    def error?
      status == :error
    end

    def to_h
      {
        provider:,
        operation:,
        status:,
        message:,
        code:,
        data:
      }
    end
  end
end
