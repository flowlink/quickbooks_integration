require 'spec_helper'

module QBIntegration
  describe SalesReceipt do
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
        "quickbooks.payment_method_name" => [{ "visa" => "Discover" }]
      }
    end

    subject { SalesReceipt.new(message, config) }

    it ".build_sales_receipt_lines" do
      expect(subject.build_sales_receipt_lines.count).to eq message[:payload][:order][:line_items].count
    end

    it "" do
      subject.save
    end

    pending ".save"
  end
end
