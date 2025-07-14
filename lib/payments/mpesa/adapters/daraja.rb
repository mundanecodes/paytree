module Payments
  module Mpesa
    module Adapters
      module Daraja
        extend Payments::FeatureSet

        supports :stk_push, :stk_query

        autoload :StkPush, "payments/mpesa/adapters/daraja/stk_push"
        autoload :StkQuery, "payments/mpesa/adapters/daraja/stk_query"
      end
    end
  end
end
