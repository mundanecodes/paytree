module Paytree
  module Mpesa
    class C2B
      def self.register_urls(**args)
        adapter = Paytree::Mpesa.config.adapter
        raise NotImplementedError unless adapter.supports?(:c2b)

        adapter::C2B.register_urls(**args)
      end

      def self.simulate(**args)
        adapter = Paytree::Mpesa.config.adapter
        raise NotImplementedError unless adapter.supports?(:c2b)

        adapter::C2B.simulate(**args)
      end
    end
  end
end
