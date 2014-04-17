require "spec_helper"

describe QBIntegration::Service::Account do
  let(:config) { Factories.config }

  subject do
    described_class.new config
  end

  it "finds account by name" do
    VCR.use_cassette("account/find_by_name", match_requests_on: [:method, :body]) do
      account = subject.find_by_name "Inventory Asset"

      expect(account.id).to be
      expect(account).to be_active
      expect(account.name).to eq "Inventory Asset"
    end
  end

  it "raises error if accound not found" do
    VCR.use_cassette("account/find_by_name_not_found") do
      expect { subject.find_by_name "Not to be found account" }.to raise_error
    end
  end
end
