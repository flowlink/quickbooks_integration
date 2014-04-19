require 'spec_helper'

module QBIntegration
  describe Stock do
    subject { described_class.new({}, config) }

    let(:config) { Factories.config }

    it "returns valid Metadata.LastUpdatedTime string" do
      VCR.use_cassette("item/find_by_updated_at", match_requests_on: [:body, :method]) do
        expect(subject.inventories.last[:quantity]).to be_a Integer
      end
    end
  end
end
