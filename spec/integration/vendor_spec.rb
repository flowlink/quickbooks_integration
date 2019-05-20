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
  let(:headers) {
    {
      "Content-Type": "application/json"
    }
  }
  let(:vendor) {
    {
      "sysid": 1103,
      "name": "Centurt Theatres",
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
          "since": "2010-03-13T14:50:22-08:00",
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
          "since": "2010-03-13T14:50:22-08:00",
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
    it "returns 200 and summary with id" do
      post '/add_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "vendor": vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end


  describe "update_vendor", vcr: true do
    it "returns 200 and summary with id" do
      post '/update_vendor', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret
        },
        "vendor": vendor
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end
end

