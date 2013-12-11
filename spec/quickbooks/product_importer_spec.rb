require "spec_helper"

describe QBIntegration::ProductImporter do
  let(:config) do
    {
      'quickbooks.access_token' => "",
      'quickbooks.access_secret' => "",
      'quickbooks.account_name' => "Inventory Asset",
      'quickbooks.realm' => "835973000"
    }
  end

  context "product:new" do
    let(:product_new) do
      {
        message: "product:new",
        message_id: 123,
        payload: {
          product: Factories.product_new(sku: "tr")
        }
      }.with_indifferent_access
    end

    subject do
      described_class.new(product_new, config)
    end

    it "creates the product if not exists" do
      expect(subject.sku).to eq 'ROR-TS'
      expect(subject.import.to_json).to eq({})
    end
  end
end
