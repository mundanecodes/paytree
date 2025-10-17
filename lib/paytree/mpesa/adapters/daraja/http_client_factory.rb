module Paytree
  module Mpesa
    module Adapters
      module Daraja
        module HttpClientFactory
          private

          # Creates a thread-safe memoized HTTP client
          # @param ivar_name [Symbol] Instance variable name (e.g., :@http_client)
          # @param plugins [Array<Symbol>] HTTPX plugins to load (e.g., [:retries])
          # @param options [Hash] Additional HTTPX options
          # @return [HTTPX::Session] Configured HTTP client
          def thread_safe_client(ivar_name, plugins: [], **options)
            cached = instance_variable_get(ivar_name)
            return cached if cached

            mutex_name = :"#{ivar_name}_mutex"
            mutex = instance_variable_get(mutex_name) || instance_variable_set(mutex_name, Mutex.new)

            mutex.synchronize do
              cached = instance_variable_get(ivar_name)
              return cached if cached

              client = plugins.reduce(HTTPX) { |c, plugin| c.plugin(plugin) }

              instance_variable_set(
                ivar_name,
                client.with(base_http_options.merge(options))
              )
            end
          end

          def base_http_options
            {
              origin: config.base_url,
              timeout: {
                connect_timeout: config.timeout / 2,
                operation_timeout: config.timeout
              },
              ssl: {
                verify_mode: OpenSSL::SSL::VERIFY_NONE
              }
            }
          end

          def retry_options
            {
              max_retries: 3,
              retry_change_requests: true,
              retry_on: ->(response) {
                # Retry on network errors (timeouts, connection failures)
                return true if response.is_a?(HTTPX::ErrorResponse)
                # Retry on 5xx server errors
                [500, 502, 503, 504].include?(response.status)
              }
            }
          end
        end
      end
    end
  end
end
