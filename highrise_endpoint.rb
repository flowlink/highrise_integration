Bundler.require(:default)
require "endpoint_base/sinatra"
Dotenv.load

module HighriseEndpoint
  class Application < EndpointBase::Sinatra::Base
    # optional security check, value supplied is compared against HTTP_X_HUB_TOKEN header
    # which is included in all requests sent by the hub, header is unique per integration.
    #
    # to opt of out security check, do not include this line
    endpoint_key ENV["ENDPOINT_KEY"]
    set :logging, true

    before do
      # Sets the Highrise credentials based on what is provided
      Highrise::Base.site = @config["highrise_site_url"]
      Highrise::Base.user = @config["highrise_api_token"]
    end

    def line_items_to_string(line_items)
      line_items.map{ |line_item|
        "##{line_item[:product_id]} - \"#{line_item[:name]}\" | #{line_item[:quantity]} @ #{line_item[:price]/100.00}/each"
      }.join("\n")
    end

    def handle_customer(payload)
      people = Highrise::Person.search(customer_id: payload[:customer][:id])

      tags = if @payload[:customer][:highrise_tags] && @payload[:customer][:highrise_tags][:person]
        @payload[:customer][:highrise_tags][:person]
      else
        []
      end

      tasks = if @payload[:customer][:highrise_tasks] && @payload[:customer][:highrise_tasks][:person]
        @payload[:customer][:highrise_tasks][:person]
      else
        []
      end

      if people.length > 0
        @person = people.first
        attr = HighriseEndpoint::PersonBlueprint.new(payload, @person).attributes

        if @person.field("Customer ID") == payload[:customer][:id]
          @person.load attr
        else
          @person = Highrise::Person.new(structure)
        end

        if @person.save
          tags.each do |tag|
            @person.tag!(tag)
          end

          tasks.each do |task|
            if ["today", "tomorrow", "this_week", "next_week", "later"].include?(task[:due])
              highrise_task = Highrise::Task.new(body: task[:body], frame: task[:due], subject_type: "Party", subject_id: @person.id, owner_id: task[:assigned_to])
            else
              highrise_task = Highrise::Task.new(body: task[:body], frame: "specific", due_at: task[:due], subject_type: "Party", subject_id: @person.id, owner_id: task[:assigned_to])
            end

            highrise_task.save
          end

          result 200, "Person was updated on Highrise."
        else
          result 500, @person.errors[:base].join("; ")
        end
      else
        structure = HighriseEndpoint::PersonBlueprint.new(payload).attributes
        @person = Highrise::Person.new(structure)

        if @person.save
          tags.each do |tag|
            @person.tag!(tag)
          end

          tasks.each do |task|
            if ["today", "tomorrow", "this_week", "next_week", "later"].include?(task[:due])
              highrise_task = Highrise::Task.new(body: task[:body], frame: task[:due], subject_type: "Party", subject_id: @person.id, owner_id: task[:assigned_to])
            else
              highrise_task = Highrise::Task.new(body: task[:body], frame: "specific", due_at: task[:due], subject_type: "Party", subject_id: @person.id, owner_id: task[:assigned_to])
            end

            highrise_task.save
          end

          result 200, "Person was added to Highrise."
        else
          result 500, @person.errors[:base].join("; ")
        end
      end
    end

    def handle_order(payload)
      deals = Highrise::Deal.all
      deals = deals.map{ |deal|
         deal if deal.name == "Order ##{payload[:order][:id]}"
      }.compact

      person = Highrise::Person.search(payload[:order][:billing_address]).first

      person_tags = if @payload[:order][:highrise_tags] &&  @payload[:order][:highrise_tags][:person]
        @payload[:order][:highrise_tags][:person]
      else
        []
      end

      person_tasks = if @payload[:order][:highrise_tasks] && @payload[:order][:highrise_tasks][:person]
        @payload[:order][:highrise_tasks][:person]
      else
        []
      end

      deal_tasks = if @payload[:order][:highrise_tasks] && @payload[:order][:highrise_tasks][:deal]
        @payload[:order][:highrise_tasks][:deal]
      else
        []
      end

      if deals.length > 0
        @deal = deals.first
        structure = HighriseEndpoint::DealBlueprint.new(payload: payload, deal: JSON.parse(@deal.to_json)).build

        if @deal.name == "Order ##{payload[:order][:id]}"
          @deal.load(structure)
        else
          @deal = Highrise::Deal.new(structure)
        end

        if @deal.save
          person_tags.each do |person_tag|
            person.tag!(person_tag)
          end

          person_tasks.each do |person_task|
            if ["today", "tomorrow", "this_week", "next_week", "later"].include?(person_task[:due])
              highrise_task = Highrise::Task.new(body: person_task[:body], frame: person_task[:due], subject_type: "Party", subject_id: person.id, owner_id: person_task[:assigned_to])
            else
              highrise_task = Highrise::Task.new(body: person_task[:body], frame: "specific", due_at: person_task[:due], subject_type: "Party", subject_id: person.id, owner_id: person_task[:assigned_to])
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

          result 200, "Deal was updated on Highrise."
        else
          result 500, @deal.errors[:base].join("; ")
        end
      else
        structure = HighriseEndpoint::DealBlueprint.new(payload: payload).build
        @deal = Highrise::Deal.new(structure)

        if @deal.save
          person_tags.each do |person_tag|
            person.tag!(person_tag)
          end

          person_tasks.each do |person_task|
            if ["today", "tomorrow", "this_week", "next_week", "later"].include?(person_task[:due])
              highrise_task = Highrise::Task.new(body: person_task[:body], frame: person_task[:due], subject_type: "Party", subject_id: person.id, owner_id: person_task[:assigned_to])
            else
              highrise_task = Highrise::Task.new(body: person_task[:body], frame: "specific", due_at: person_task[:due], subject_type: "Party", subject_id: person.id, owner_id: person_task[:assigned_to])
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

          @note = Highrise::Note.create(body: line_items_to_string(payload[:order][:line_items]), subject_id: @deal.id, subject_type: "Deal")

          result 200, "Deal was added to Highrise."
        else
          result 500, @deal.errors[:base].join("; ")
        end
      end
    end

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

    ["/add_customer", "/update_customer"].each do |path|
      post path do
        handle_customer @payload
      end
    end

    ["/add_order", "/update_order"].each do |path|
      post path do
        handle_order @payload
      end
    end

    ["/add_shipment", "/update_shipment"].each do |path|
      post path do
        handle_shipment @payload
      end
    end
  end
end
