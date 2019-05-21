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

  let(:item_purchase_order) {
    {
      "id": "SYS-4",
      "email": "",
      "source": "test.com",
      "status": "RECEIVED",
      "totals": {
        "tax": 0,
        "item": 10,
        "order": 10,
        "refund": 0,
        "payment": nil,
        "discount": 0,
        "shipping": 0
      },
      "refunds": [],
      "currency": "USD",
      "placed_on": "2019-02-21T20:54:32.079Z",
      "updated_at": "2019-02-21T20:56:09.475Z",
      "line_items": [
        {
          "sku": "Benson Dining Chair",
          "quantity": 996,
          "price": 0.0,
          "id": "VI10325",
          "name": "Benson Dining Chair"
        }
      ],
      "adjustments": [
        {
          "name": "Tax",
          "value": 0
        },
        {
          "name": "Shipping",
          "value": 0
        },
        {
          "name": "Discounts",
          "value": 0
        }
      ],
      "form_number": "4",
      "tax_line_items": nil,
      "contact": {
        "email": "test@email.com",
        "job_title": nil,
        "name": "John Doe",
        "phone": nil,
        "sysid": 26968
      },
      "contact_company": {
        "city": "Dayton",
        "country": "United States",
        "logo_url": "https://systum-production-prod-east-1.s3.amazonaws.com/47/logo-finalnobg.png",
        "name": "Polymer80",
        "phone": "+1 8005171243",
        "post_code": "89403",
        "status": "ACTIVE",
        "sysid": 47,
        "url": "www.test.com"
      },
      "supplier_address": {
        "city": "Victor",
        "phone": "+1 585-333-1111",
        "state": "New York",
        "company": nil,
        "country": "United States",
        "zipcode": "14564",
        "address1": "PO 300",
        "address2": "123 Main Rd",
        "name": "Regal Industrial Sales"
      },
      "shipping_address": {
        "city": "Dayton",
        "phone": "+1 8005171243",
        "state": "Nevada",
        "company": nil,
        "country": "United States",
        "zipcode": "89403",
        "address1": "123 2nd Street",
        "name": "Fulfillment"
      },
      "supplier": {
        "name": "Regal Industrial Sales",
        "country": "United States",
        "created_at": nil,
        "email": "orders@test.com",
        "type": nil,
        "locale": "New York",
        "street1": "PO Box 355",
        "city": "Victor",
        "post_code": "14564",
      }
    }
  }

  let(:account_purchase_order) {
    {
      "id": "SYS-4",
      "email": "",
      "source": "test.com",
      "status": "RECEIVED",
      "totals": {
        "tax": 0,
        "item": 0.48000000000000004,
        "order": 0.48000000000000004,
        "refund": 0,
        "payment": nil,
        "discount": 0,
        "shipping": 0
      },
      "refunds": [],
      "currency": "USD",
      "placed_on": "2019-02-21T20:54:32.079Z",
      "updated_at": "2019-02-21T20:56:09.475Z",
      "line_items": [
        {
          "sku": "Mastercard",
          "price": 10.0,
          "id": "VI10325",
          "name": "Mastercard"
        }
      ],
      "adjustments": [
        {
          "name": "Tax",
          "value": 0
        },
        {
          "name": "Shipping",
          "value": 0
        },
        {
          "name": "Discounts",
          "value": 0
        }
      ],
      "form_number": "4",
      "tax_line_items": nil,
      "contact": {
        "email": "test@email.com",
        "job_title": nil,
        "name": "John Doe",
        "phone": nil,
        "sysid": 26968
      },
      "contact_company": {
        "city": "Dayton",
        "country": "United States",
        "logo_url": "https://systum-production-prod-east-1.s3.amazonaws.com/47/logo-finalnobg.png",
        "name": "Polymer80",
        "phone": "+1 8005171243",
        "post_code": "89403",
        "status": "ACTIVE",
        "sysid": 47,
        "url": "www.test.com"
      },
      "supplier_address": {
        "city": "Victor",
        "phone": "+1 585-333-1111",
        "state": "New York",
        "company": nil,
        "country": "United States",
        "zipcode": "14564",
        "address1": "PO 300",
        "address2": "123 Main Rd",
        "name": "Regal Industrial Sales"
      },
      "shipping_address": {
        "city": "Dayton",
        "phone": "+1 8005171243",
        "state": "Nevada",
        "company": nil,
        "country": "United States",
        "zipcode": "89403",
        "address1": "123 2nd Street",
        "name": "Fulfillment"
      },
      "supplier": {
        "name": "Regal Industrial Sales",
        "country": "United States",
        "created_at": nil,
        "email": "orders@test.com",
        "type": nil,
        "locale": "New York",
        "street1": "PO Box 355",
        "city": "Victor",
        "post_code": "14564",
      }
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#add_purchase_order", vcr: { record: :new_episodes } do
    it "returns 200 for an item based" do
      merged_po = item_purchase_order.merge({
      })
      post '/add_purchase_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_account_name": "Accounts Payable (A/P)",
          "quickbooks_vendor_name": "Books by Bessie",
          "quickbooks_create_or_update": "1"
        },
        "purchase_order": item_purchase_order
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 for an account based expense" do
      post '/add_purchase_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_account_name": "Accounts Payable (A/P)",
          "quickbooks_vendor_name": "Books by Bessie",
          "quickbooks_create_or_update": "1"
        },
        "purchase_order": account_purchase_order
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end

  describe "updated_purchase_order", vcr: { record: :new_episodes } do
    it "returns 200 with a qbo_id" do
      merged_po = item_purchase_order.merge({
        qbo_id: 1315,
      })

      post '/update_purchase_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_account_name": "Accounts Payable (A/P)",
          "quickbooks_vendor_name": "Books by Bessie",
          "quickbooks_create_or_update": "1"
        },
        "purchase_order": merged_po
      }.to_json, headers
      expect(last_response.status).to eq 200
    end

    it "returns 200 with a doc nunber" do
      merged_po = item_purchase_order.merge({
        id: 'SYS-4',
      })

      post '/update_purchase_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_account_name": "Accounts Payable (A/P)",
          "quickbooks_vendor_name": "Books by Bessie",
          "quickbooks_create_or_update": "1"
        },
        "purchase_order": merged_po
      }.to_json, headers
      expect(last_response.status).to eq 200
    end
  end
end
