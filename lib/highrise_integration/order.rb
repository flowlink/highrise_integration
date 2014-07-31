module HighriseIntegration
  class Order
    attr_reader :order

    def initialize(payload)
      @order = payload[:order]
    end

    def current_deal
      if order[:highrise_id]
        @current_deal ||= begin
                            Highrise::Deal.find order[:highrise_id]
                          rescue ActiveResource::ResourceNotFound
                          end
      end
    end

    def current_deal?
      current_deal
    end
  end
end
