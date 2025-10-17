module Paytree
  module Utils
    module ErrorHandling
      def with_error_handling(context: nil)
        yield
      rescue Paytree::Errors::ValidationError,
        Paytree::Errors::Base => e
        emit_error(e, context)
        raise
      rescue HTTPX::TimeoutError => e
        handle_http_error(
          e,
          context,
          error_class: Paytree::Errors::MpesaResponseError,
          error_type: "Timeout"
        )
      rescue JSON::ParserError => e
        handle_http_error(
          e,
          context,
          error_class: Paytree::Errors::MpesaMalformedResponse,
          error_type: "Malformed response"
        )
      rescue HTTPX::HTTPError => e
        if e.response.status >= 500
          handle_http_error(
            e,
            context,
            error_class: Paytree::Errors::MpesaServerError,
            error_type: "Server error",
            extract_info: true
          )
        else
          handle_http_error(
            e,
            context,
            error_class: Paytree::Errors::MpesaClientError,
            error_type: "Client error",
            extract_info: true
          )
        end
      rescue HTTPX::Error => e
        handle_http_error(
          e,
          context,
          error_class: Paytree::Errors::MpesaResponseError,
          error_type: "HTTP error"
        )
      rescue => e
        wrap_and_raise(
          Paytree::Errors::Base,
          "Unexpected error in #{context}: #{e.message}",
          e, context
        )
      end

      private

      def handle_http_error(error, context, error_class:, error_type:, extract_info: false)
        if extract_info
          info = parse_http_error(error)
          message = info[:message] || error.message
          code = info[:code]
        else
          message = error.message
          code = case error
          when Net::OpenTimeout then "timeout.connection"
          when Net::ReadTimeout then "timeout.read"
          when Faraday::TimeoutError then "timeout.request"
          end
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

      def emit_error(error, context, **metadata)
        config = get_config_for_context(context)
        logger = config.respond_to?(:logger) ? config.logger : Logger.new($stdout)

        logger.error format_error_message(error, context)
      end

      def get_config_for_context(context)
        provider = extract_provider_from_context(context) || :mpesa
        Paytree[provider]
      end

      def extract_provider_from_context(context)
        return :mpesa if context.to_s.downcase.include?("mpesa")
        # Can be extended to support other providers based on context
        nil
      end

      def parse_http_error(http_error)
        return {} unless http_error.respond_to?(:response)

        body = begin
          http_error.response.json
        rescue
          http_error.response.body.to_s
        end
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
