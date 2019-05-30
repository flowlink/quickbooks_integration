require_relative 'spec_helper'

describe 'App' do
  let(:headers) {
    {
      "Content-Type": "application/json"
    }
  }
  let(:realm) { ENV['quickbooks_realm'] }
  let(:secret) { ENV['quickbooks_access_secret'] }
  let(:token) { ENV['quickbooks_access_token'] }
  let(:customer){
    {
      "name": "Spec test 2",
      "email": "test@gmail.com",
      "is_b2b": nil,
      "systum_id": 1176,
      "external_id": "8000000C-1550867897",
      "account_number": nil,
      "billing_address": {
        "city": "Somewhere",
        "phone": nil,
        "state": "California",
        "company": nil,
        "country": "United States",
        "zipcode": nil,
        "address1": "1234 Main Drive",
        "address2": nil,
        "lastname": "Smith",
        "firstname": ""
      },
      "shipping_address": {
        "city": "Somewhere",
        "phone": nil,
        "state": "California",
        "company": nil,
        "country": "United States",
        "zipcode": nil,
        "address1": "1234 Main Drive",
        "address2": nil,
        "lastname": "Smith",
        "firstname": ""
      }
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#get_customers", vcr: true do
    it "first page returns 206 and list of 50 vendors" do
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
    it "returns 500 due to multiple customers" do
      merged_customer = customer.merge({
        "name": "no-matching-display-name"
      })
      post '/add_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "customer": merged_customer
      }.to_json, headers
      data = JSON.parse(last_response.body)
      expect(last_response.status).to eq 500
      expect(data["summary"]). to eq("Multiple customers found with email: test@gmail.com")
    end

    it "returns 200 and summary when using qbo_id" do
      merged_customer = customer.merge({
        'qbo_id': 161
      })
      post '/add_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "customer": merged_customer
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 and summary when using display name" do
      merged_customer = customer.merge({
        "name": "Tony Stark"
      })
      post '/add_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "customer": merged_customer
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 and summary when using unique email" do
      merged_customer = customer.merge({
        "email": "developoment+wootest@nurelm.com"
      })
      post '/add_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "create_or_update": "1"
        },
        "customer": merged_customer
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end


  describe "update_customer", vcr: true do
    it "returns 200 and summary with id" do
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

    it "returns 500 and summary when using a non unique email" do
      merged_customer = customer.merge({
        name: '',

      })
      post '/update_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret
        },
        "customer": merged_customer
      }.to_json, headers
      expect(last_response.status).to eq 500
    end

    it "returns 200 and summary when using an email" do
      merged_customer = customer.merge({
        name: '',
        email: "developoment+wootest@nurelm.com"
      })
      post '/update_customer', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret
        },
        "customer": merged_customer
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end
end

