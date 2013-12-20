require 'spec_helper'

module QBIntegration
  module Service
    describe SalesReceipt do
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
          "quickbooks.web_orders_user" => "false"
        }
      end

      subject { SalesReceipt.new(config, payload) }

      it "persist new sales receipt" do
        VCR.use_cassette("sales_receipt/persist_new_receipt") do
          sales_receipt = subject.create

          expect(sales_receipt.doc_number).to eq Factories.order["number"]
        end
      end

      it "finds by order number" do
        VCR.use_cassette("sales_receipt/find_by_order_number") do
          sales_receipt = subject.find_by_order_number
          expect(sales_receipt.doc_number).to eq Factories.order["number"]
        end
      end

      it "updates existing sales receipt" do
        payload[:order][:email] = "updated@mail.com"

        VCR.use_cassette("sales_receipt/sync_updated_order") do
          sales_receipt = subject.update subject.find_by_order_number
          expect(sales_receipt.bill_email.address).to eq "updated@mail.com"
        end
      end

      it "appends ship tracking number if available on update" do
        payload[:order][:shipments].first[:tracking] = "IamAString"
        VCR.use_cassette("sales_receipt/sync_updated_order_with_tracking_number") do
          sales_receipt = subject.update subject.find_by_order_number
          expect(sales_receipt.tracking_num).to match "IamAString"
        end
      end
    end
  end
end
