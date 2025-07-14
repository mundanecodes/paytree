module Payments
  module Mpesa
    module Adapters
      module Daraja
        extend Payments::FeatureSet

        supports :stk_push
        # You can uncomment more as you implement them:
        # supports :stk_query, :b2c, :b2b, :reversal, :c2b_register, :c2b_simulate, :balance

        autoload :Base, "payments/mpesa/adapters/daraja/base"
        autoload :StkPush, "payments/mpesa/adapters/daraja/stk_push"
        # autoload :StkQuery, "payments/mpesa/adapters/daraja/stk_query" (future)
      end
    end
  end
end
