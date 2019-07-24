require_relative 'spec_helper'

describe 'App' do
  let(:realm) { ENV['quickbooks_realm'] }
  let(:secret) { ENV['quickbooks_access_secret'] }
  let(:token) { ENV['quickbooks_access_token'] }
  let(:headers) {
    {
      "Content-Type": "application/json"
    }
  }

  let(:payload) {
    {
      purchase_order: {
        id: "1013"
      },
      id: "bill-026",
      quantity: "24"
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#add_bill_purchase_order", vcr: true do
    it "returns 200 when creating a new bill" do
      post '/add_bill_to_purchase_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
        },
        "bill": payload
      }.to_json, headers
      puts last_response.body.inspect
      expect(last_response.status).to eq 200
    end

  end
end
