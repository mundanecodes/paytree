module Paytree
  module Mpesa
    module Adapters
      module Daraja
        extend Paytree::FeatureSet

        supports :stk_push, :stk_query, :b2c, :c2b, :b2b

        autoload :StkPush, "paytree/mpesa/adapters/daraja/stk_push"
        autoload :StkQuery, "paytree/mpesa/adapters/daraja/stk_query"
        autoload :B2C, "paytree/mpesa/adapters/daraja/b2c"
        autoload :C2B, "paytree/mpesa/adapters/daraja/c2b"
        autoload :B2B, "paytree/mpesa/adapters/daraja/b2b"
      end
    end
  end
end
