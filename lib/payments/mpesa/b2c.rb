module Payments
  module Mpesa
    class B2C
      def self.call(**args)
        adapter = Payments::Mpesa.config.adapter

        unless adapter.respond_to?(:supports?) && adapter.supports?(:b2c)
          raise NotImplementedError, "B2C not supported by #{adapter}"
        end

        adapter::B2C.call(**args)
      end
    end
  end
end
