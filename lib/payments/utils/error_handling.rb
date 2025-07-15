module Payments
  module Utils
    module ErrorHandling
      def with_error_handling(context: nil)
        yield
      rescue Payments::Errors::ValidationError => e
        emit_error(e, context)

        raise
      rescue Payments::Errors::Base => e
        emit_error(e, context)

        raise
      rescue Faraday::TimeoutError => e
        error = Payments::Errors::MpesaResponseError.new("Timeout in #{context}: #{e.message}")
        emit_error(error, context)

        raise error
      rescue Faraday::ParsingError, JSON::ParserError => e
        error = Payments::Errors::MpesaMalformedResponse.new("Malformed response in #{context}: #{e.message}")
        emit_error(error, context)

        raise error
      rescue => e
        error = Payments::Errors::Base.new("Unexpected error in #{context}: #{e.message}")
        emit_error(error, context)

        raise error
      end

      def emit_error(error, context)
        config = Payments[:mpesa]
        return unless config.respond_to?(:on_error)

        handler = config.on_error
        raise ArgumentError, "on_error must be callable" if handler && !handler.respond_to?(:call)

        handler&.call(error, context)
      end

      def trigger_success(result, context)
        config = Payments[:mpesa]
        return unless config.respond_to?(:on_success)

        handler = config.on_success
        raise ArgumentError, "on_success must be callable" if handler && !handler.respond_to?(:call)

        handler&.call(result, context)
      end
    end
  end
end
