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

    def build_note
      "Line Items: \n\n #{line_items_note}\n\n" <<
      "Adjustments: \n\n #{adjustments_note}\n\n" <<
      "Payments: \n\n #{payments_note}"
    end

    def build_update_note(deal)
      update = ""

      # Ensure notes are ordered by creation date so we always compare
      # with latest update
      ordered_notes = deal.notes.sort_by { |n| n.created_at }.reverse

      if !target_note("Line Items", ordered_notes).include?(line_items_note)
        update << "Line Items Updated: \n\n #{line_items_note}\n\n"
      end

      if !target_note("Adjustments", ordered_notes).include?(adjustments_note)
        update << "Adjustments Updated: \n\n #{adjustments_note}\n\n"
      end

      if !target_note("Payments", ordered_notes).include?(payments_note)
        update << "Payments Updated: \n\n #{payments_note}\n\n"
      end

      update
    end

    # Picks the last note where the term shows up
    #
    #   e.g. Line Items
    #
    def target_note(term, notes)
      if note = notes.select { |n| n.body.include? term }.first
        note.body
      else
        ""
      end
    end

    def line_items_note
      (order[:line_items] || []).map { |line_item|
        " ##{line_item[:product_id]} - \"#{line_item[:name]}\" | #{line_item[:quantity]} @ #{line_item[:price]}/each"
      }.join("\n")
    end

    def adjustments_note
      (order[:adjustments] || []).map { |a|
        " ##{a[:name]} : $ #{a[:value]}"
      }.join("\n")
    end

    def payments_note
      (order[:payments] || []).map { |p|
        " # #{p[:number]} - #{p[:status]} | $ #{p[:amount]} via #{p[:payment_method]}"
      }.join("\n")
    end
  end
end
