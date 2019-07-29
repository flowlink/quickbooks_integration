require_relative 'spec_helper'
require 'pp'

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
      id: "1013",
      line_items: [
        name: "Battery Wall Mirror",
        price: 35.0,
        product: {
          "name": "Battery Wall Mirror",
          "sysid": 1185,
        },
        quantity: 1,
        systum_id: 2044,
        product_id: "SWS03",
        discount_value: 0.0
      ],
      quantity_received: 24
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#add_bill_purchase_order", vcr: true do
    it "returns 200 when creating a new bill" do
      expected_po = {
        id: "1013",
        quantity_received: 24,
        quantity_received_in_qbo: [
          {
            "line_item_name" => "Battery Wall Mirror",
            "quantity_received_so_far" => 24
          }
        ]
      }
      post '/add_bill_to_purchase_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
        },
        "purchase_order": payload
      }.to_json, headers
      data = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(data["purchase_orders"][0]["quantity_received"]).to eq expected_po[:quantity_received]
      expect(data["purchase_orders"][0]["quantity_received_in_qbo"][0]).to eq expected_po[:quantity_received_in_qbo][0]
    end

  end
end
