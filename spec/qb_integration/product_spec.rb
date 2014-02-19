require "spec_helper"

describe QBIntegration::Product do
  subject do
    described_class.new(product_message, config)
  end

  let(:config) { Factories.config }

  context "error handling" do
    let(:product_message) do
      {
        message: "product:new",
        message_id: 123,
        payload: {
          product: Factories.product
        }
      }.with_indifferent_access
    end

    context "missing parameters" do
      let(:config) {{}}

      it "generates an error notification" do
        VCR.use_cassette "product_importer/missing_config", match_requests_on: [:method, :body] do
          code, notification = subject.import

          expect(code).to eq 500
          expect(notification["notifications"].count).to eq 1
          expect(notification["notifications"][0]["subject"]).to include "key not found"
        end
      end
    end

    context "account not found" do
      let(:config) do
        c = Factories.config
        c["quickbooks.income_account"] = "Not to be found"
        c
      end

      it "generates an error notification" do
        VCR.use_cassette "product/missing_account", match_requests_on: [:method, :body] do
          code, notification = subject.import

          expect(code).to eq 500
          expect(notification["notifications"].count).to eq 1
          expect(notification["notifications"][0]["subject"]).to include "No Account"
        end
      end
    end
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
      VCR.use_cassette "product/update_variants", match_requests_on: [:method, :body] do
        code, note = subject.import

        expect(code).to eq 200
        expect(note["notifications"].count).to eq 3
        expect(note["notifications"][0]["subject"]).to include "Product ROR-TS updated"
        expect(note["notifications"][1]["subject"]).to include "Product ROR-TS-v-1 updated"
        expect(note["notifications"][2]["subject"]).to include "Product ROR-TS-v-2 updated"
      end
    end
  end

  context "products doesnt exist" do
    context "product with variants" do
      let(:product_message) do
        {
          message: "product:new",
          message_id: 123,
          payload: {
            product: Factories.product('families')
          }
        }.with_indifferent_access
      end

      it "creates the product" do
        VCR.use_cassette "product/new_variants", match_requests_on: [:method, :body] do
          code, notification = subject.import

          expect(code).to eq 200
          expect(notification["notifications"].count).to eq 3
          expect(notification["notifications"][0]["subject"]).to include "families"
          expect(notification["notifications"][1]["subject"]).to include "families-v-1"
          expect(notification["notifications"][2]["subject"]).to include "families-v-2"
        end
      end

      context "user check track inventory flag" do
        it "sets product to track inventory" do
          config['quickbooks.track_inventory'] = "true"
          product_message[:payload][:product] = Factories.product('grilos-grilos')
          subject.stub time_now: "2014-02-17"

          VCR.use_cassette "product/track_inventory", match_requests_on: [:method, :body] do
            code, note = subject.import
            expect(code).to eq 200

            attrs = subject.send :attributes, subject.product_payload
            expect(attrs[:track_quantity_on_hand]).to be
          end
        end
      end
    end

    context "product without variants" do
      let(:product_message) do
        {
          message: "product:new",
          message_id: 123,
          payload: {
            product: Factories.product_without_variants('NIN')
          }
        }.with_indifferent_access
      end

      it "creates the product" do
        VCR.use_cassette "product/new_without_variants", match_requests_on: [:method, :body] do
          code, notification = subject.import

          expect(code).to eq 200
          expect(notification["notifications"][0]["subject"]).to include "Product NIN imported"
        end
      end

      it "ensures unit price is persisted" do
        product_message[:payload][:product] = Factories.product_without_variants('Second Thing')

        VCR.use_cassette "product/price_check", match_requests_on: [:method, :body] do
          code, notification = subject.import
          expect(code).to eq 200

          item = subject.item_service.find_by_sku "Second Thing"
          expect(item.unit_price).to be > 0
        end
      end
    end
  end
end
