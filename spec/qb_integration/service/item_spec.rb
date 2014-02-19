require "spec_helper"

describe QBIntegration::Service::Item do
  let(:config) { Factories.config }

  subject do
    described_class.new config
  end

  it "finds items by sku" do
    VCR.use_cassette("item/find_by_sku", match_requests_on: [:method, :body]) do
      item = subject.find_by_sku('T-SHIRT-PUGS-RULE')

      expect(item.name).to eq 'T-SHIRT-PUGS-RULE'
      expect(item.description).to eq 'Pug life chose me.'
      expect(item.unit_price).to eq 19.90
    end
  end

  it "finds item which tracks inventory" do
    VCR.use_cassette("item/find_item_track_inventory", match_requests_on: [:body, :method]) do
      item = subject.find_by_sku "4553254352"
      expect(item.quantity_on_hand.to_i).to eq 56
    end
  end

  it "creates an item with given attributes" do
    VCR.use_cassette("item/create", match_requests_on: [:method, :body]) do
      item = subject.create({
        name: "NEW-SKU-HERE",
        description: "Something witty.",
        unit_price: 99.90
      })

      expect(item.id).to be
      expect(item.active).to be
      expect(item.name).to eq 'NEW-SKU-HERE'
      expect(item.unit_price.to_f).to eq 99.90
    end
  end

  it "updates an item with given attributes" do
    VCR.use_cassette "item/update", match_requests_on: [:method, :body] do
      item_to_update = subject.find_by_sku('NEW-SKU-HERE')
      item = subject.update(item_to_update, { description: "new description" })

      expect(item.id).to eq item_to_update.id
      expect(item.active).to be
      expect(item.description).to eq "new description"
    end
  end

  context ".find_or_create_by_sku" do
    let(:line_item) { Factories.order["line_items"].last.with_indifferent_access }

    it "creates new item when it's not there already" do
      line_item[:sku] = 'T-SHIRT-PUGS-RULE'

      VCR.use_cassette "item/find_or_create", match_requests_on: [:method, :body] do
        subject.stub find_by_sku: nil
        item = subject.find_or_create_by_sku line_item
        expect(item.name).to eq line_item[:sku]
      end
    end

    it "returns existing item" do
      VCR.use_cassette("item/find_by_sku", match_requests_on: [:method, :body]) do
        line_item[:sku] = 'T-SHIRT-PUGS-RULE'
        item = subject.find_or_create_by_sku line_item
        expect(item.name).to eq line_item[:sku]
      end
    end
  end
end
