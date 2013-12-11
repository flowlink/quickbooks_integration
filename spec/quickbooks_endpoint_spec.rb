require 'spec_helper'

describe QuickbooksEndpoint do

  def auth
    {'HTTP_X_AUGURY_TOKEN' => 'x123'}
  end

  def app
    described_class
  end

  describe "/product_persist" do
  end

  describe "persist" do
    context "with order:new" do
      let(:message) {
        {
          "message" => "order:new",
          :message_id => "abc",
          :payload => {
            "order" => Factories.order,
            "original" => Factories.original,
            "parameters" => Factories.parameters
          }
        }
      }
      it "generates a json response with an info notification" do
        CrossReference.any_instance.stub(:lookup).with("R181807170").and_return(nil)
        VCR.use_cassette('online/persist_new_order') do
          post '/persist', message.to_json, auth
          last_response.status.should eql 200
          response = JSON.parse(last_response.body)

          response["message_id"].should eql "abc"
          response["notifications"].first["subject"].should eql "Created Quickbooks sales receipt 45 for order R181807170"
          response["notifications"].first["description"].should eql "Quickbooks SalesReceipt id = 45 and idDomain = QBO"
        end
      end
    end

    context "with order:updated" do
      let(:message) {
        {
          "message" => "order:updated",
          :message_id => 'abc',
          :payload => {
            "order" => Factories.order(Factories.order_changes),
            "original" => Factories.original,
            "parameters" => Factories.parameters
          }
        }
      }

      it "generates a json response with the update info notification" do
        VCR.use_cassette('online/persist_updated_order') do
          post '/persist', message.to_json, auth
          last_response.status.should eql 200
          response = JSON.parse(last_response.body)
          response["message_id"].should eql "abc"
          response["notifications"].first["subject"].should eql "Updated the Quickbooks sales receipt 45 for order R181807170"
          response["notifications"].first["description"].should eql "Quickbooks SalesReceipt id = 45 and idDomain = QBO"
        end
      end
    end
  end
end
