require "spec_helper"

describe Quickbooks::Helper do

  let(:config_param) {config(message) }

  context "#payment_method_names" do
    let(:service) { client.create_service("PaymentMethod") }
    let(:client) { Quickbooks::Base.client(message[:payload], "abc", config_param, message["message"]) }

    context "on Quickbooks online" do

      let(:message) {
        {
          "message" => "order:new",
          'message_id' => 'abc',
          :payload => {
            "order" => Factories.order,
            "original" => Factories.original,
            "parameters" => Factories.parameters
          }
        }
      }

      let(:payment_names_hash) {
        {
          "1" => "Cash",
          "2" => "Check",
          "3" => "Visa",
          "4" => "MasterCard",
          "5" => "American Express",
          "6" => "Diners Club",
          "7" => "Discover"
        }
      }
      it "returns a id:name hash of payment methods in Quickbooks" do
        VCR.use_cassette("online/helper_payment_method_names") do
          subject.payment_method_names(service).should eql payment_names_hash
        end
      end
    end

  end

end
