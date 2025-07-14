module Payments
  module Mpesa
    module Adapters
      module Daraja
        extend Payments::FeatureSet

        supports :stk_push, :stk_query, :b2c

        autoload :StkPush, "payments/mpesa/adapters/daraja/stk_push"
        autoload :StkQuery, "payments/mpesa/adapters/daraja/stk_query"
        autoload :B2C, "payments/mpesa/adapters/daraja/b2c"
      end
    end
  end
end
