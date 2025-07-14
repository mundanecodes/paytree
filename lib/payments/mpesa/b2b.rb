module Payments
  module Mpesa
    class B2B
      def self.call(**args)
        adapter = Payments::Mpesa.config.adapter

        unless adapter.respond_to?(:supports?) && adapter.supports?(:b2b)
          raise NotImplementedError, "B2B not supported by #{adapter}"
        end

        adapter::B2B.call(**args)
      end
    end
  end
end
