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
  let(:vendor) {
    {
      "sysid": 1103,
      "street1": "PO Box 355",
      "city": "Victor",
      "country": "United States",
      "taxId": "EID_",
      "email": "orders@regalisi.com",
      "phone": "+1 585-398-1290",
      "taxCalculation": false,
      "suppliedProducts": [],
      "status": "ACTIVE"
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#get_vendors", vcr: true do
    it "returns 206 and list of vendors" do
      post '/get_vendors', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_since": "2010-03-13T14:50:22-08:00",
          "page": "1",
          "per_page": "25"
        }
      }.to_json, headers
      vendors = JSON.parse(last_response.body)['vendors']
      expect(last_response.status).to eq 206
      expect(vendors.size).to eq 25
    end

    it "returns 200 and list of vendors" do
      post '/get_vendors', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_since": "2010-03-13T14:50:22-08:00",
          "page": 2,
          "per_page": 25
        }
      }.to_json, headers
      vendors = JSON.parse(last_response.body)['vendors']
      expect(last_response.status).to eq 200
      expect(vendors.size).to eq 15
    end
  end

  describe "add_vendor", vcr: true do
    it "returns 200 and summary when using display name to match" do
      merged_vendor = vendor.merge({
        name: "Company 1",
      })

      post '/add_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
        },
        "vendor": merged_vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 and summary when using qbo_id to match" do
      merged_vendor = vendor.merge({
        qbo_id: 149,
      })

      post '/add_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
        },
        "vendor": merged_vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 and summary with new company name" do
      merged_vendor = vendor.merge({
        name: "Ollivander's",
      })

      post '/add_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "vendor": merged_vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end


  describe "update_vendor", vcr: true do
    it "returns 200 and with a qbo_id" do
      merged_vendor = vendor.merge({
        qbo_id: 149,
      })

      post '/update_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret
        },
        "vendor": merged_vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 and with a display name" do
      merged_vendor = vendor.merge({
        name: "Company 1",
      })

      post '/update_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret
        },
        "vendor": merged_vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end
end

