require 'rack/test'
require 'rubygems'
require 'bundler'
require 'vcr'
Bundler.require(:default, :test)
require File.join(File.dirname(__FILE__), '..', '../lib/qb_integration.rb')
require File.join(File.dirname(__FILE__), '..', '../quickbooks_endpoint')

VCR.configure do |c|
  c.cassette_library_dir = "spec/vcr"
  c.hook_into :webmock
  c.filter_sensitive_data('<REALM>') { ENV.fetch('quickbooks_realm') }
  c.filter_sensitive_data('<TOKEN>') { ENV.fetch('quickbooks_access_token') }
  c.filter_sensitive_data('<SECRET>') { ENV.fetch('quickbooks_access_secret') }
  c.configure_rspec_metadata!
end

describe 'App' do
  let(:realm) { ENV['quickbooks_realm'] }
  let(:secret) { ENV['quickbooks_access_secret'] }
  let(:token) { ENV['quickbooks_access_token'] }
  let(:customer) {
    {
      "name": "Spec test 2",
      "email": "test@gmail.com",
      "phone": "+1 1111111111",
      "emailPreference": "opt_in",
      "mobile": "+1 2222222222",
      "individual": false,
      "socials": {},
      "customFields": [
        {
          "DLRPTCTNEXP": ""
        },
        {
          "DLRPTCTN": ""
        },
        {
          "TYPNC": ""
        },
        {
          "DEMO": ""
        },
        {
          "TYPBDS": ""
        },
        {
          "NBRBDS": ""
        },
        {
          "Total Beds": ""
        },
        {
          "Type of Beds": ""
        },
        {
          "Type of Nursecall": ""
        },
        {
          "Demo Sent?": ""
        },
        {
          "Dealer Protection": ""
        },
        {
          "Website": ""
        },
        {
          "Account Type": ""
        }
      ],
      "isB2b": true,
      "since": "2019-03-05T17:01:05.845Z",
      "lastTransaction": "2019-04-22T16:29:50.392Z",
      "numberOfTransactions": 11,
      "status": "ACTIVE",
      "subStatus": "",
      "site_id": nil,
      "addresses": [
        {
          "sysid": 184185,
          "street1": "6900 Dallas Parkway",
          "street2": "",
          "street3": "",
          "isDefault": true,
          "city": "Plano",
          "postCode": "75024",
          "country": "United States",
          "locale": "Texas",
          "status": "ACTIVE",
          "name": "Systum Test",
          "dateCreated": "2019-03-05T17:01:46.026Z",
          "type": "SHIPPING"
        },
        {
          "sysid": 184184,
          "street1": "6900 Dallas Parkway",
          "street2": "",
          "street3": "",
          "isDefault": true,
          "city": "Plano",
          "postCode": "75024",
          "country": "United States",
          "locale": "Texas",
          "status": "ACTIVE",
          "name": "Systum Test",
          "dateCreated": "2019-03-05T17:01:46.026Z",
          "type": "BILLING"
        }
      ],
      "formNumber": "3145",
      "hideCarts": false,
      "carts": []
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#get_customers", vcr: true do
    it "first page returns 206 and list of 50 vendors" do
      headers = {
        "Content-Type": "application/json"
      }
      post '/get_customers', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_since": "2010-03-13T14:50:22-08:00",
          "quickbooks_page_num": "1",
        }
      }.to_json, headers
      customers = JSON.parse(last_response.body)['customers']
      expect(last_response.status).to eq 206
      expect(customers.size).to eq 50
    end

    it "second page returns 206 and list of 50 vendors" do
      headers = {
        "Content-Type": "application/json"
      }
      post '/get_customers', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "since": "2010-03-13T14:50:22-08:00",
          "quickbooks_since": "2010-03-13T14:50:22-08:00",
          "quickbooks_page_num": "2",
        }
      }.to_json, headers
      customers = JSON.parse(last_response.body)['customers']
      expect(last_response.status).to eq 206
      expect(customers.size).to eq 50
    end
  end

  describe "add_customer", vcr: true do
    it "returns 200 and summary with id" do
      headers = {
        "Content-Type": "application/json"
      }
      post '/add_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "customer": customer
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end


  describe "update_customer", vcr: true do
    it "returns 200 and summary with id" do
      headers = {
        "Content-Type": "application/json"
      }
      post '/update_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret
        },
        "customer": customer
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end
end

