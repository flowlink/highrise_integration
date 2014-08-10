require "spec_helper"

describe HighriseEndpoint::Application do
  include_examples "config hash"

  context "customers" do
    let(:payload) do
      config.merge({ customer: Factories.customer_payload })
    end

    it "updates a Person record" do
      VCR.use_cassette("/customer/update") do
        post "update_customer", payload.to_json, auth
        expect(last_response.status).to eq 200
      end
    end
  end

  context "orders" do
    it "updates a Deal record" do
      payload = config.merge({ order: Factories.order_payload })

      VCR.use_cassette("/order/update") do
        post "update_order", payload.to_json, auth
        expect(last_response.status).to eq 200
      end
    end

    it "creates a Deal record" do
      payload = config.merge({ order: Factories.add_order_payload })

      VCR.use_cassette("/order/create") do
        post "add_order", payload.to_json, auth
        expect(last_response.status).to eq 200
      end
    end

    it "creates a customer on the fly" do
      payload = config.merge({ order: Factories.add_order_payload })

      payload[:order][:id] = "R32i534588976"
      payload[:order][:email] = "luis@spreecommerce.com"
      payload[:order][:billing_address][:firstname] = "Luis"
      payload[:order][:billing_address][:lasname] = "Braga"

      VCR.use_cassette("/order/add_with_customer") do
        post "add_order", payload.to_json, auth
        expect(last_response.status).to eq 200
      end
    end
  end
end
