module HighriseIntegration
  class Shipment
    # We'd need to figure how to link Orders (Deals) to Shipments before
    # putting this code into use
    def handle_shipment(payload)
      @shipment = payload[:shipment]

      deals = Highrise::Deal.all
      deals = deals.map{ |deal|
        deal if deal.name == "Order ##{@shipment[:order_id]}"
      }.compact

      @deal = deals.first

      person_tasks = if @payload[:shipment][:highrise_tasks] && @payload[:shipment][:highrise_tasks][:person]
        @payload[:shipment][:highrise_tasks][:person]
      else
        []
      end

      deal_tasks = if @payload[:shipment][:highrise_tasks] && @payload[:shipment][:highrise_tasks][:deal]
        @payload[:shipment][:highrise_tasks][:deal]
      else
        []
      end

      if @deal
        address = @shipment[:shipping_address]

        formatted_address = <<-FORMATTED_ADDRESS
#{address[:firstname]} #{address[:lastname]}
#{address[:address1]}
#{address[:address2]}
#{address[:city]}, #{address[:state]}, #{address[:country]} #{address[:zipcode]}
FORMATTED_ADDRESS

        shipment_body = <<-SHIPMENT_BODY
Tracking: #{@shipment[:tracking] ? @shipment[:tracking] : "No tracking code for this shipment."}

Shipped to:
#{formatted_address}

Manifest:
#{line_items_to_string(@shipment[:items])}

Shipped On: #{@shipment[:shipped_at] ? @shipment[:shipped_at] : "Not yet shipped."}
SHIPMENT_BODY

        @note = Highrise::Note.create(body: shipment_body, subject_id: @deal.id, subject_type: "Deal")

        person_tasks.each do |person_task|
          if ["today", "tomorrow", "this_week", "next_week", "later"].include?(person_task[:due])
            highrise_task = Highrise::Task.new(body: person_task[:body], frame: person_task[:due], subject_type: "Party", subject_id: @deal.party.id, owner_id: person_task[:assigned_to])
          else
            highrise_task = Highrise::Task.new(body: person_task[:body], frame: "specific", due_at: person_task[:due], subject_type: "Party", subject_id: @deal.party.id, owner_id: person_task[:assigned_to])
          end

          highrise_task.save
        end

        deal_tasks.each do |deal_task|
          if ["today", "tomorrow", "this_week", "next_week", "later"].include?(deal_task[:due])
            highrise_task = Highrise::Task.new(body: deal_task[:body], frame: deal_task[:due], subject_type: "Deal", subject_id: @deal.id, owner_id: deal_task[:assigned_to])
          else
            highrise_task = Highrise::Task.new(body: deal_task[:body], frame: "specific", due_at: deal_task[:due], subject_type: "Deal", subject_id: @deal.id, owner_id: deal_task[:assigned_to])
          end

          highrise_task.save
        end


        if @note.save
          result 200, "Shipment info was added to deal: #{@deal.name}"
        else
          result 500, @note.errors[:base].join(", ")
        end
      end
    end
  end
end
