module Payments
  module FeatureSet
    def supports(*list)
      @features = list.map(&:to_sym)
    end

    def features
      @features || []
    end

    def supports?(feature)
      features.include?(feature.to_sym)
    end
  end
end
