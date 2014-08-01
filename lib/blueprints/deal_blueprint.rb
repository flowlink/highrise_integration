# This is a monkey patch to allow Highrise to not give a 422 about having party/parties nested.
module Highrise
  class Deal
    def encode_with_nested_attribute_exclusion(options={})
      encode_without_nested_attribute_exclusion({:except => [:party, :parties]}.merge(options))
    end
    alias_method_chain :encode, :nested_attribute_exclusion
  end
end

module HighriseEndpoint
  class DealBlueprint
    # A deal hash structure, if provided the blueprint hash structure will only include what has changed
    attr_accessor :order, :deal

    def initialize(payload, deal = nil)
      @order = payload[:order]
      @deal = deal
    end

    def attributes
      person = Highrise::Person.search(email: order[:email]).first

      {
        currency: order[:currency],
        name:     "Order ##{order[:id]}",
        price:    order[:totals][:order],
        status:   "won",
        party_id: person ? person.id : nil
      }.with_indifferent_access
    end
  end
end
