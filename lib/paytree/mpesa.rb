module Paytree
  module Mpesa
    autoload :Adapters, "paytree/mpesa/adapters"

    def self.config
      Paytree[:mpesa]
    end
  end
end
