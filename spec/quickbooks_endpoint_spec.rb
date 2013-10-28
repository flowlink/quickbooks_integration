require 'spec_helper'

describe QuickbooksEndpoint do

  def auth
    {'HTTP_X_AUGURY_TOKEN' => 'x123'}
  end

  def app
    described_class
  end


  context "persist" do
    context "with order:new" do
      context "online" do
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

        it "should respond to POST 'persist'" do
          VCR.use_cassette('online/persist_new_order') do
            post '/persist', message.to_json, auth
            last_response.status.should eql 200
            response = JSON.parse(last_response.body)

            response["message_id"].should eql "abc"
            response["notifications"].first["subject"].should eql "persisted order R181807170 in Quickbooks"
            response["notifications"].first["description"].should eql "Quickbooks SalesReceipt id = 36 and idDomain = QBO"
          end
        end
      end
    end
  end

end
