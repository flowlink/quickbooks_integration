require 'spec_helper'

module QBIntegration
  describe PaymentMethod do
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
        'quickbooks.realm' => "123",
        'quickbooks.access_token' => "123",
        'quickbooks.access_secret' => "123"
      }
    end

    subject { PaymentMethod.new Base.new(message, config) }

    context ".augury_name" do
      it "picks credit card if provided" do
        message[:payload][:original][:credit_cards][0][:cc_type] = "Visa"
        expect(subject.augury_name).to eq "Visa"
      end

      it "picks payment method name if credit card not provided" do
        message[:payload][:original][:credit_cards] = []
        expect(subject.augury_name).to eq payload[:order][:payments].first[:payment_method]
      end
    end

    context ".matching_payment" do
      before do
        config["quickbooks.payment_method_name"] = [{ "visa" => "Discover" }]
      end

      it "maps qb_name and store names properly" do
        expect(subject.qb_name).to eq "Discover"
      end

      it "raise when cant find method in quickbooks" do
        subject.service.stub fetch_by_name: nil

        expect {
          subject.matching_payment
        }.to raise_error
      end

      pending "mock real request with vcr"
    end
  end
end
