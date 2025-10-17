module Paytree
  module Mpesa
    module Adapters
      module Daraja
        # Validation module for M-Pesa API operations
        # Validates required fields, config values, and operation-specific parameters
        module Validator
          VALIDATIONS = {
            c2b_register: {required: %i[short_code confirmation_url validation_url]},
            c2b_simulate: {required: %i[phone_number amount reference]},
            stk_push: {required: %i[phone_number amount reference]},
            b2c: {required: %i[phone_number amount], config: %i[result_url]},
            b2b: {
              required: %i[short_code receiver_shortcode account_reference amount],
              config: %i[result_url timeout_url],
              command_id: %w[BusinessPayBill BusinessBuyGoods]
            }
          }.freeze

          # Validates parameters for a given operation
          # @param operation [Symbol] The operation to validate for (e.g., :stk_push, :b2c)
          # @param params [Hash] Parameters to validate
          # @raise [Paytree::Errors::UnsupportedOperation] if operation is unknown
          # @raise [Paytree::Errors::ValidationError] if validation fails
          # @raise [Paytree::Errors::ConfigurationError] if required config is missing
          def validate_for(operation, params = {})
            rules = VALIDATIONS[operation] ||
              raise(Paytree::Errors::UnsupportedOperation, "Unknown operation: #{operation}")

            # Validate required fields
            Array(rules[:required]).each { |field| validate_field(field, params[field]) }

            # Validate required config values
            Array(rules[:config]).each do |key|
              unless config.extras[key]
                raise Paytree::Errors::ConfigurationError, "Missing `#{key}` in Mpesa extras config"
              end
            end

            # Validate command_id if specified
            if (allowed = rules[:command_id]) && !allowed.include?(params[:command_id])
              raise Paytree::Errors::ValidationError,
                "command_id must be one of: #{allowed.join(", ")}"
            end
          end

          # Validates a single field based on its type
          # @param field [Symbol] Field name
          # @param value [Object] Field value to validate
          # @raise [Paytree::Errors::ValidationError] if validation fails
          def validate_field(field, value)
            case field
            when :amount then validate_amount(value)
            when :phone_number then validate_phone_number(value)
            else
              validate_presence(field, value)
            end
          end

          private

          # Validates amount is a positive number
          def validate_amount(value)
            unless value.is_a?(Numeric) && value >= 1
              raise Paytree::Errors::ValidationError,
                "amount must be a positive number"
            end
          end

          # Validates phone number is in valid Kenyan format (254XXXXXXXXX)
          def validate_phone_number(value)
            phone_regex = /^254\d{9}$/
            unless value.to_s.match?(phone_regex)
              raise Paytree::Errors::ValidationError,
                "phone_number must be a valid Kenyan format (254XXXXXXXXX)"
            end
          end

          # Validates field is not blank
          def validate_presence(field, value)
            if value.to_s.strip.empty?
              raise Paytree::Errors::ValidationError, "#{field} cannot be blank"
            end
          end
        end
      end
    end
  end
end
