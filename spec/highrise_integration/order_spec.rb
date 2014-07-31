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
  end
end
