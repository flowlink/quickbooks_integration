require 'spec_helper'

module QBIntegration
  module Service
    describe Customer do
      let(:payload) do
        {
          "order" => Factories.order,
          "original" => Factories.original
        }.with_indifferent_access
      end

      let(:message) do
        { :payload => payload }.with_indifferent_access
      end

      let(:config) do
        {
        'quickbooks.realm' => "1014843225",
        'quickbooks.access_token' => "qyprdINz6x1Qccyyj7XjELX7qxFBE9CSTeNLmbPYb7oMoktC",
        'quickbooks.access_secret' => "wiCLZbYVDH94UgmJDdDWxpYFG2CAh30v0sOjOsDX",
        }
      end

      subject { Customer.new config, payload }

      it "fetchs customer given name" do
        VCR.use_cassette "customer/customer_fetch" do
          customer = subject.fetch_by_display_name
          expect(customer.display_name).to eq subject.display_name
        end
      end

      context "customer doesnt exist" do
        before { subject.stub fetch_by_display_name: nil }

        it "creates a new customer" do
          subject.stub display_name: "Spree Commerce"

          VCR.use_cassette "customer/customer_create" do
            expect(subject.find_or_create.display_name).to eq "Spree Commerce"
          end
        end
      end
    end
  end
end
