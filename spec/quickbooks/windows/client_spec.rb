require "spec_helper"

describe Quickbooks::Windows::Client do

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

  let(:config_param) {config(message) }
  let(:client) { Quickbooks::Base.client(message[:payload], "abc", config_param) }


  context "build_receipt_header" do
    it "will add the correct class_name" do
      header = client.build_receipt_header
      header.class_name.should eql "DRTL LTS"
    end
  end

end