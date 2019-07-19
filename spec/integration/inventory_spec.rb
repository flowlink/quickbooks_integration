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

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#get_inventory", vcr: { record: :new_episodes } do
    it "returns 200" do
      post '/get_inventory', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          quickbooks_poll_stock_timestamp: "2019-02-05T18:48:56.001Z"
        },
      }.to_json, headers
      body = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      body["inventories"].each do |inventory|
        expect(inventory).to include "id"
        expect(inventory).to include "product_id"
        expect(inventory).to include "quantity"
        expect(inventory).to include "updated_at"
      end
    end

  end
end

