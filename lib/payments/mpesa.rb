require "payments/concerns/feature_set"

module Payments
  module Mpesa
    extend Payments::FeatureSet
    supports :stk_push

    autoload :StkPush, "payments/mpesa/stk_push"
    autoload :Adapters, "payments/mpesa/adapters"

    def self.config
      Payments[:mpesa]
    end
  end
end
