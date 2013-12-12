require "spec_helper"

describe QBIntegration::ProductImporter do
  let(:config) { Factories.config }

  subject do
    described_class.new(product_message, config)
  end

  context "product already exists" do
    let(:product_message) do
      {
        message: "product:new",
        message_id: 123,
        payload: {
          product: Factories.product
        }
      }.with_indifferent_access
    end

    it "updates the product" do
      VCR.use_cassette "product_importer/product_update" do
        code, notification = subject.import

        description = "Updated product with Sku = ROR-TS on Quickbooks successfully."

        expect(code).to eq 200
        expect(notification["notifications"].first["subject"]).to eq description
      end
    end
  end

  context "product doesnt exist" do
    let(:product_message) do
      {
        message: "product:new",
        message_id: 123,
        payload: {
          product: Factories.product('NEW-SHINY-PRODUCT')
        }
      }.with_indifferent_access
    end

    it "creates the product" do
      VCR.use_cassette "product_importer/product_new" do
        code, notification = subject.import

        description = "Imported product with Sku = NEW-SHINY-PRODUCT to Quickbooks successfully."

        expect(code).to eq 200
        expect(notification["notifications"].first["subject"]).to eq description
      end
    end
  end
end
