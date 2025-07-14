module Payments
  module Mpesa
    module Adapters
      module Daraja
        extend Payments::FeatureSet

        supports :stk_push, :stk_query, :b2c, :c2b

        autoload :StkPush, "payments/mpesa/adapters/daraja/stk_push"
        autoload :StkQuery, "payments/mpesa/adapters/daraja/stk_query"
        autoload :B2C, "payments/mpesa/adapters/daraja/b2c"
        autoload :C2B, "payments/mpesa/adapters/daraja/c2b"
      end
    end
  end
end
