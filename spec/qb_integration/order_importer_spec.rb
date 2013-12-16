require 'spec_helper'

module QBIntegration
  describe OrderImporter do
    let(:message) do
      {
        "message" => "order:new",
        :message_id => "abc",
        :payload => {
          "order" => Factories.order,
          "original" => Factories.original,
          "parameters" => Factories.parameters
        }
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

    subject { OrderImporter.new(message, config) }

    it "sync new order" do
      message[:payload][:order][:number] = "R13MENGAO"
      message[:payload][:order][:placed_on] = "2013-12-16 14:51:18 -0300"

      VCR.use_cassette("sales_receipt/sync_order_sales_receipt") do
        code, notification = subject.sync

        expect(code).to eq 200
        expect(notification[:notifications][:level]).to eq 'info'
        expect(notification[:notifications][:subject]).to match message[:payload][:order][:number]
      end
    end
  end
end
