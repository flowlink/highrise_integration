require "endpoint_base/sinatra"

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
      if @config.is_a? Hash
        Highrise::Base.site = @config["highrise_site_url"]
        Highrise::Base.user = @config["highrise_api_token"]
      end
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
      @order = HighriseIntegration::Order.new(@payload)

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

      if @order.current_deal?
        @deal = @order.current_deal
        structure = HighriseEndpoint::DealBlueprint.new(payload: payload, deal: JSON.parse(@deal.to_json)).build
        @deal.load(structure)

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

          @note = Highrise::Note.create(body: @order.line_items_note, subject_id: @deal.id, subject_type: "Deal")

          add_object "order", { id: @payload[:order][:id], highrise_id: @deal.id }
          result 200, "Deal was added to Highrise."
        else
          result 500, @deal.errors[:base].join("; ")
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
  end
end
