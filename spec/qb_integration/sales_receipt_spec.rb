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
        'quickbooks.realm' => "123",
        'quickbooks.access_token' => "123",
        'quickbooks.access_secret' => "123"
      }
    end

    subject { SalesReceipt.new(message, config) }

    it ".build_sales_receipt_lines" do
      expect(subject.build_sales_receipt_lines.count).to eq message[:payload][:order][:line_items].count
    end

    pending ".save"
  end
end
