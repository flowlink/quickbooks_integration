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
  let(:invoice) {
    {
      "id": "7215",
      "tax": 0.0,
      "type": "Invoice",
      "email": "test@gmail.com",
      "quickbooks_ar_account_name": "Accounts Receivable (A/R)",
      "items": [
        {
          "tax": 0.0,
          "quickbooks_cogs_account": "Cost of Goods Sold",
          "name": "l, white",
          "price": 13.0,
          "sysid": 5292,
          "product": {
            "name": "T-Shirt",
            "tags": [

            ],
            "type": "type",
            "sysid": 2691,
            "season": "ALL",
            "status": "ACTIVE",
            "styleId": "",
            "isVirtual": false,
            "description": "",
            "hasVariants": true,
            "isBillOfMaterial": false,
            "isManualLotNumber": true,
            "requiresLotNumbers": false,
            "requiresSerialNumbers": false
          },
          "currency": "USD",
          "quantity": 1,
          "totalPrice": 13.0,
          "discountValue": 0.0,
          "promoDiscount": 0.0,
          "taxableAmount": 13.0,
          "discountPercent": 0.0
        },
        {
          "tax": 0.0,
          "quickbooks_cogs_account": "Cost of Goods Sold",
          "name": "NONAME",
          "price": 45.0,
          "sysid": 5294,
          "product": {
            "name": "Dropship",
            "tags": [

            ],
            "type": "type",
            "sysid": 2693,
            "season": "ALL",
            "status": "ACTIVE",
            "styleId": "",
            "taxCode": "",
            "isVirtual": true,
            "description": "",
            "hasVariants": false,
            "isBillOfMaterial": false,
            "isManualLotNumber": true,
            "requiresLotNumbers": false,
            "requiresSerialNumbers": false
          },
          "currency": "USD",
          "quantity": 1,
          "imageUrls": [

          ],
          "totalPrice": 45.0,
          "discountValue": 0.0,
          "promoDiscount": 0.0,
          "taxableAmount": 45.0,
          "discountPercent": 0.0
        }
      ],
      "promo": 0.0,
      "title": "Test invoice 2",
      "total": 58.0,
      "number": 13,
      "status": "OPEN",
      "currency": nil,
      "customer": {
        "name": "Test User",
        "email": "test@gmail.com",
        "is_b2b": true,
        "systum_id": 2308,
        "account_number": nil,
        "billing_address": nil,
        "shipping_address": nil
      },
      "shipping": 0.0,
      "systum_id": 7202,
      "line_items": [
        {
          "id": "2",
          "amount": 39.0,
          "product_id": "testing",
          "line_num": 1,
          "description": "T-Shirt, purple",
          "detail_type": "SalesItemLineDetail",
          "line_detail": {
            "item": {
              "id": "60",
              "name": "T-Shirt:l, pruple"
            },
            "class": {
            },
            "quantity": 3.0,
            "tax_code": {
              "id": "NON",
              "name": nil
            },
            "unit_price": 13.0,
            "price_level": {
            },
            "rate_percent": nil,
            "service_date": nil
          },
          "price": 13,
          "quantity": 1
        }
      ],
      "updated_at": "2019-05-21",
      "due_date": "2019-06-20",
      "created_at": "2019-06-20 16:29:01 -0700",
      "form_number": "IN13",
      "grand_total": 58.0,
      "paid_amount": 0,
      "billing_address": {
        "city": "asdfasd",
        "name": "sdfasdf",
        "phone": nil,
        "state": "Texas",
        "company": nil,
        "country": "United States",
        "zipcode": "75024",
        "address1": "sdfasdf",
        "address2": nil
      },
      "shipping_address": {
        "city": "asdfasd",
        "name": "Quynh Giao ",
        "phone": nil,
        "state": "Texas",
        "company": nil,
        "country": "United States",
        "zipcode": "75024",
        "address1": "ksadfjlaskd",
        "address2": "ksajldfk"
      },
      "purchase_order_number": nil,
      "purchase_order_contact": nil
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#get_invoices", vcr: true do
    it "returns 206 and list of vendors" do
      post '/get_invoices', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_since": "2017-03-11T18:48:56.001Z",
          "quickbooks_page_num": "1"
        }
      }.to_json, headers
      invoices = JSON.parse(last_response.body)['invoices']
      expect(last_response.status).to eq 200
      expect(invoices.size).to eq 12
    end
  end

  describe "#add_invoice", vcr: { record: :new_episodes } do
    it "returns 200 and a summary" do
      skip("Getting Transaction Date Error even though inventory start date is prev year")
      post '/add_invoice', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_tax_item": "product_tax",
          "quickbooks_discount_item": "discount",
          "quickbooks_shipping_item": "shipping",
          "quickbooks_track_inventory": "1",
          "quickbooks_account_name": "Sales of Product Income",
          "quickbooks_web_orders_users": "0",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_cogs_account": "Cost of Goods Sold",
          "quickbooks_create_new_product": "1"
        },
        invoice: invoice
      }.to_json, headers
      body = JSON.parse(last_response.body)
      p body
      expect(last_response.status).to eq 200
    end
  end

end
