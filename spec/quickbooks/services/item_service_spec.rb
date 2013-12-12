require "spec_helper"

describe QBIntegration::Service::Item do
  let(:config) do
    {
      'quickbooks.access_token' => "qyprdhjEBfA2BI8sD7fWVPH4wL9esaKrYeWLosiPBir3pa5j",
      'quickbooks.access_secret' => "yU7RtuM1Lot803jkkCfcyV9GePoNZGnZO8nRbBxo",
      'quickbooks.account_name' => "Inventory Asset",
      'quickbooks.realm' => "835973000"
    }
  end

  subject do
    described_class.new config
  end

  it "finds items by sku" do
    VCR.use_cassette("item/find_by_sku") do
      item = subject.find_by_sku('T-SHIRT-PUGS-RULE')

      expect(item.name).to eq 'T-SHIRT-PUGS-RULE'
      expect(item.description).to eq 'Pug life chose me.'
      expect(item.unit_price).to eq 19.90
    end
  end

  it "creates an item with given attributes" do
    VCR.use_cassette("item/create") do
      item = subject.create({
        name: "NEW-SKU-HERE",
        description: "Something witty.",
        unit_price: 99.90
      })

      expect(item.id).to be
      expect(item.active).to be
      expect(item.name).to eq 'NEW-SKU-HERE'
    end
  end

  it "updates an item with given attributes" do
    VCR.use_cassette "item/update" do
      item_to_update = subject.find_by_sku('T-SHIRT-PUGS-RULE')

      id = item_to_update.id

      item = subject.update(item_to_update, {
        description: "new description"
      })

      expect(item.id).to eq id
      expect(item.active).to be
      expect(item.description).to eq "new description"
    end
  end
end
