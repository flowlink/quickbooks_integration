require 'spec_helper'

describe QuickbooksEndpoint do

  def auth
    {'HTTP_X_AUGURY_TOKEN' => 'x123'}
  end

  def app
    described_class
  end


  context "windows" do
    context "persist" do
    end
  end

  context "online" do

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

    context "persist" do

      it "should respond to POST 'persist'" do
        post '/persist', message.to_json, auth
        puts last_response.body.inspect
        last_response.status.should == 200
        last_response.body.should match /"message":"email:sent"/
      end

    end
  end

end
