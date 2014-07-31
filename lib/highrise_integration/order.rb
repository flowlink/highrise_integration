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

    def line_items_note
      (order[:line_items] || []).map { |line_item|
        " ##{line_item[:product_id]} - \"#{line_item[:name]}\" | #{line_item[:quantity]} @ #{line_item[:price]}/each"
      }.join("\n")
    end

    def adjustments_note
      (order[:adjustments] || []).map { |a|
        " #{a[:name]} : #{a[:value]}"
      }.join("\n")
    end
  end
end
