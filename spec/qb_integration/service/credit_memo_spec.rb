require 'spec_helper'

module QBIntegration
  module Service
    describe CreditMemo do
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
          "quickbooks.discount_item" => "Discount"
        }
      end

      subject { CreditMemo.new(config, payload) }

      it "creates from sales receipt" do
        payload[:order][:number] = "R518606166"
        payload[:order][:totals][:order] = "125.70"

        VCR.use_cassette("credit_memo/create_from_receipt") do
          sales_receipt = Service::SalesReceipt.new(config, payload).find_by_order_number
          credit_memo = subject.create_from_receipt sales_receipt
          expect(credit_memo.doc_number).to eq sales_receipt.doc_number
        end
      end
    end
  end
end
