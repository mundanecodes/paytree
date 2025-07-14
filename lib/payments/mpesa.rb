module Payments
  module Mpesa
    autoload :Adapters, "payments/mpesa/adapters"

    def self.config
      Payments[:mpesa]
    end
  end
end
