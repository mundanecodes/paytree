module Paytree
  module Mpesa
    class StkQuery
      def self.call(**args)
        adapter = Paytree::Mpesa.config.adapter

        unless adapter.respond_to?(:supports?) && adapter.supports?(:stk_query)
          raise NotImplementedError, "STK Query not supported by #{adapter}"
        end

        adapter::StkQuery.call(**args)
      end
    end
  end
end
