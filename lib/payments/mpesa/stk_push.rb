module Payments
  module Mpesa
    class StkPush
      def self.call(**args)
        adapter = Payments::Mpesa.config.adapter || Adapters::Daraja

        unless adapter.respond_to?(:supports?) && adapter.supports?(:stk_push)
          raise NotImplementedError, "STK Push not supported by #{adapter}"
        end

        adapter::StkPush.call(**args)
      end
    end
  end
end
