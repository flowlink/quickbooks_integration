require "spec_helper"

describe Quickbooks::Base do

  let(:message) {
    {
      "message" => "order:new",
      :payload => {
        "order" => Factories.order,
        "original" => Factories.original,
        "parameters" => Factories.parameters
      }
    }
  }

  context ".client" do
    it "raise InvalidPlatformException when config has invalid platform" do
      expect {
        Quickbooks::Base.client({},"",{"quickbooks.platform" => "smoke"},message["message"])
      }.to raise_error(Quickbooks::InvalidPlatformException, /We cannot create the/)
    end

    it "initializes the correct platform client" do
      client = Quickbooks::Base.client({},"",{"quickbooks.platform" => "online"}, message["message"])
      client.class.should eql Quickbooks::Online::Client
    end
  end

  context "Quickeebooks dynamics" do

    let(:config) {
      {
        'quickbooks.realm' => "abc",
        'quickbooks.access_token' => "23243fdsfser23t4gs",
        'quickbooks.access_secret' => "abc23refsv32rfwe",
        'quickbooks.platform' => "online"
      }
    }

    let(:client) { Quickbooks::Base.client({},"",config,message["message"]) }

    context "#create_service" do
      it "returns the service instance based on platform" do
        client.create_service("Customer").class.should eql Quickeebooks::Online::Service::Customer
      end

      it "raises an exception when the platform does not support the service" do
        expect {
          client.status_service
        }.to raise_error(Quickbooks::UnsupportedException, "status_service is not supported for Quickbooks Online")
      end
    end

    context "#create_model" do
      it "returns the model instance based on platform" do
        client.create_model("Address").class.should eql Quickeebooks::Online::Model::Address
      end
    end
  end

  context "#get_config!" do
    it "raises an exception when the key is not present in the config" do
      expect {
        Quickbooks::Base.new({},"",{},"", message["message"]).get_config!("bla")
      }.to raise_error(Quickbooks::LookupValueNotFoundException, /Can't find the key/)
    end
  end

  context "#payment_method_name" do

    let(:payload) {
      {"original" => Factories.original}
    }

    let(:client_base) {
      Quickbooks::Base.new(payload,"",{},"","order:new")
    }

    context "with credit_card" do
      it "returns the cc_type when there is a credit_card" do
        client_base.payment_method_name.should eql "visa"
      end
    end

    context "with no credit_card present" do

      let(:payload) {
        {"original" => Factories.original.tap{ |x| x.delete("credit_cards")} }
      }

      it "returns the payment_method name when no credit_card present" do
        client_base.payment_method_name.should eql "Check"
      end
    end

    context "with no payments present" do
      let(:payload) {
        {"original" => Factories.original.tap{ |x| x.delete("credit_cards")}.tap{|x|x.delete("payments")} }
      }

      it "returns 'None' as payment_method_name" do
        client_base.payment_method_name.should eql "None"
      end
    end
  end

  context "#deposit_account_name" do
    let(:config_param) {config(message)}
    let(:client_base) {
      Quickbooks::Base.new(message[:payload],"",config_param,"","order:new")
    }

    it "will use the mapping based on the payment_method_name" do
      client_base.deposit_account_name("visa").should eql "Visa/MC"
    end

    it "will raise an exception when no mapping found" do
      expect{
        client_base.deposit_account_name("cash")
      }.to raise_error(Quickbooks::LookupValueNotFoundException, /Can't find the key/)
    end
  end

  context "#build_receipt_header" do
    let(:config_param) {config(message)}
    let(:client_base) {
      Quickbooks::Base.new(message[:payload],"",config_param,"Windows","order:new")
    }

    it "set the correct vars" do
      receipt_header = client_base.build_receipt_header
      receipt_header.class.should eql Quickeebooks::Windows::Model::SalesReceiptHeader
      receipt_header.doc_number.should eql "R181807170"
      receipt_header.deposit_to_account_name.should eql "Visa/MC"
      receipt_header.total_amount.should eql 114.95
      receipt_header.shipping_address.class.should eql Quickeebooks::Windows::Model::Address
      receipt_header.ship_method_name.should eql "UPS"
      receipt_header.payment_method_name.should eql "Visa"
    end
  end

  context "#persist" do
    let(:config_param) {config(message)}

    it "raises an exception when there is a cross reference present with 'order:new' message" do
      CrossReference.any_instance.stub(:lookup).with("R181807170").and_return({:id => 14, :id_domain => "QBO"})
      client = Quickbooks::Base.client(message[:payload],"",config_param, "order:new")
      expect {
        client.persist
      }.to raise_error Quickbooks::AlreadyPersistedOrderAsNew
    end
  end

end