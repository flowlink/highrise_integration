module HighriseEndpoint
  # Maps a request payload into a highrise hash structure
  class PersonBlueprint
    attr_reader :person, :customer, :billing_address, :contact_data

    def initialize(payload, person = nil)
      @person = person
      @customer = payload[:customer] 
      @billing_address = customer[:billing_address] if customer

      @contact_data = person.contact_data if person
    end

    def email_addresses
      if contact_data
        emails = contact_data.email_addresses.map(&:address)
      end

      if contact_data.nil? || (contact_data && !emails.include?(customer[:email]))
        [{ address: customer[:email], location: 'Work' }]
      else
        []
      end
    end

    def phone_numbers
      if contact_data
        numbers = contact_data.phone_numbers.map(&:number)
      end

      if contact_data.nil? || (contact_data && !numbers.include?(billing_address[:phone]))
        [{ number: billing_address[:phone], location: 'Work' }]
      else
        []
      end
    end

    def addresses
      if contact_data
        existing_address = contact_data.addresses.any? do |a|
          a.city == billing_address[:city] &&
          a.country == billing_address[:country] &&
          a.state == billing_address[:state] &&
          a.street == billing_address[:address1] &&
          a.zip == billing_address[:zipcode]
        end
      end

      if contact_data.nil? || !existing_address
        [
          {
            city:     billing_address[:city],
            country:  billing_address[:country],
            location: 'Work',
            state:    billing_address[:state],
            street:   billing_address[:address1],
            zip:      billing_address[:zipcode]
          }
        ]
      else
        []
      end
    end

    def attributes
      {
        first_name: customer[:firstname],
        last_name:  customer[:lastname],
        contact_data: {
          email_addresses: email_addresses,
          addresses: addresses,
          phone_numbers: phone_numbers,
          customer_id: customer[:id]
        }
      }.with_indifferent_access
    end

    def build
      customer ? attributes : {}
    end
  end
end
