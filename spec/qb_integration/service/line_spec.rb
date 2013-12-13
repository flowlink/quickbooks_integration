require 'spec_helper'

module QBIntegration
  module Service
    describe Line do
      let(:payload) do
        {
          "order" => Factories.order,
          "original" => Factories.original
        }.with_indifferent_access
      end

      let(:config) do
        {
          'quickbooks.realm' => "1014843225",
          'quickbooks.access_token' => "qyprdINz6x1Qccyyj7XjELX7qxFBE9CSTeNLmbPYb7oMoktC",
          'quickbooks.access_secret' => "wiCLZbYVDH94UgmJDdDWxpYFG2CAh30v0sOjOsDX",
          "quickbooks.payment_method_name" => [{ "visa" => "Discover" }],
          'quickbooks.account_name' => "Inventory Asset",
          "quickbooks.shipping_item" => "Shipping Charges",
          "quickbooks.tax_item" => "State Sales Tax-NY",
          "quickbooks.discount_item" => "Discount",
        }
      end

      subject { Line.new config, payload }

      let(:account) { double("Account", id: 76) }

      it ".build_from_line_items" do
        VCR.use_cassette("line/build_from_line_items") do
          expect(subject.build_from_line_items(account).count).to eq payload[:order][:line_items].count
        end
      end

      it ".build_from_adjustments" do
        VCR.use_cassette("line/build_from_adjustments") do
          expect(subject.build_from_adjustments(account).count).to eq payload[:original][:adjustments].count
        end
      end

      it "just build" do
        VCR.use_cassette("line/build_them_all") do
          total = payload[:original][:adjustments].count + payload[:order][:line_items].count
          expect(subject.build_lines.count).to eq total
        end
      end

      context "returns the adjustments without originator_type" do
        it "returns as discount if amount < 0.0" do
          adjustment = { amount: "-5.0", originator_type: nil }
          expect(subject.map_adjustment_sku adjustment).to eq config.fetch("quickbooks.discount_item")
        end
      end
    end
  end
end
