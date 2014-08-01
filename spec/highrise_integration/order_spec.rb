require 'spec_helper'

module HighriseIntegration
  describe Order do
    include_examples "connect params"

    let(:payload) do
      { order: Factories.order_payload }
    end

    subject { described_class.new payload }

    it "finds existing Deal" do
      payload[:order][:highrise_id] = "3827779"

      VCR.use_cassette("order/existing") do
        expect(subject.current_deal).to be_a Highrise::Deal
      end
    end

    it "doesnt raise if not found" do
      payload[:order][:highrise_id] = "nope"

      VCR.use_cassette("order/dont_exist") do
        expect(subject.current_deal).to eq nil
      end
    end

    it "builds an update note" do
      diff = "Check update #{Time.now}"
      payload[:order][:payments][0][:payment_method] = diff
      payload[:order][:line_items][0][:name] = diff
      payload[:order][:adjustments][0][:name] = diff

      payload[:order][:highrise_id] = "3829841"

      VCR.use_cassette("order/update_existing") do
        deal = subject.current_deal
        update = subject.build_update_note deal

        expect(update).to match /Line Items Update/i
        expect(update).to match /Adjustments Update/i
        expect(update).to match /Payments Update/i
      end
    end
  end
end
