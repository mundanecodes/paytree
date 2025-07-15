module Payments
  module Utils
    module ErrorHandling
      def with_error_handling(context: nil)
        yield
      rescue Payments::Errors::ValidationError,
        Payments::Errors::Base => e
        emit_error(e, context)
        raise
      rescue Faraday::TimeoutError => e
        handle_faraday_error(
          e,
          context,
          error_class: Payments::Errors::MpesaResponseError,
          error_type: "Timeout"
        )
      rescue Faraday::ParsingError, JSON::ParserError => e
        handle_faraday_error(
          e,
          context,
          error_class: Payments::Errors::MpesaMalformedResponse,
          error_type: "Malformed response"
        )
      rescue Faraday::ClientError => e
        handle_faraday_error(
          e,
          context,
          error_class: Payments::Errors::MpesaClientError,
          error_type: "Client error",
          extract_info: true
        )
      rescue Faraday::ServerError => e
        handle_faraday_error(
          e,
          context,
          error_class: Payments::Errors::MpesaServerError,
          error_type: "Server error",
          extract_info: true
        )
      rescue => e
        wrap_and_raise(
          Payments::Errors::Base,
          "Unexpected error in #{context}: #{e.message}",
          e, context
        )
      end

      private

      def handle_faraday_error(error, context, error_class:, error_type:, extract_info: false)
        if extract_info
          info = parse_faraday_error(error)
          message = info[:message] || error.message
          code = info[:code]
        else
          message = error.message
          code = nil
        end

        wrap_and_raise(
          error_class, "#{error_type} in #{context}: #{message}", error, context, code
        )
      end

      def wrap_and_raise(klass, message, original, context, code = nil)
        error = klass.new(message)
        error.define_singleton_method(:code) { code } if code
        emit_error(error, context)

        raise error
      end

      def emit_error(error, context)
        config = get_config_for_context(context)
        logger = config.respond_to?(:logger) ? config.logger : Logger.new($stdout)

        logger.error format_error_message(error, context)

        if config.respond_to?(:on_error)
          handler = config.on_error
          raise ArgumentError, "on_error must be callable" if handler && !handler.respond_to?(:call)
          handler&.call(error, context)
        end
      end

      def trigger_success(result, context)
        config = get_config_for_context(context)

        if config.respond_to?(:on_success)
          handler = config.on_success
          raise ArgumentError, "on_success must be callable" if handler && !handler.respond_to?(:call)
          handler&.call(result, context)
        end
      end

      def get_config_for_context(context)
        provider = extract_provider_from_context(context) || :mpesa
        Payments[provider]
      end

      def extract_provider_from_context(context)
        return :mpesa if context.to_s.downcase.include?("mpesa")
        # Can be extended to support other providers based on context
        nil
      end

      def parse_faraday_error(faraday_error)
        body = faraday_error.response&.dig(:body)
        return {} unless body.is_a?(Hash)

        {
          message: body["errorMessage"] ||
            body["ResponseDescription"] ||
            body["ResultDesc"],
          code: body["errorCode"] ||
            body["ResponseCode"] ||
            body["ResultCode"]
        }
      rescue NoMethodError, KeyError, TypeError
        {}
      end

      def format_error_message(error, context)
        provider = extract_provider_from_context(context) || :mpesa
        code = (error.respond_to?(:code) && error.code) ? " (code: #{error.code})" : ""
        "[#{provider.to_s.upcase}/#{context}] #{error.class}: #{error.message}#{code}"
      end
    end
  end
end
