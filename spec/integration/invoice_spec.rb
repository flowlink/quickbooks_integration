require_relative 'spec_helper'
require "pp"

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

  let(:existing_invoice) {
    {"id"=>"1045",
     "q_id"=>"1177",
     "due_date"=>"2019-04-05",
     "created_at"=>"2019-03-06 10:43:14 -0800",
     "customer_memo"=>"Thank you for your business and have a great day!",
     "ship_date"=>nil,
     "tracking_num"=>nil,
     "total"=>0.0,
     "home_total"=>0.0,
     "auto_doc_number"=>nil,
     "doc_number"=>"1045",
     "txn_date"=>"2019-03-06",
     "apply_tax_after_discount"=>false,
     "print_status"=>"NeedToPrint",
     "email_status"=>"NotSet",
     "balance"=>0.0,
     "home_balance"=>0.0,
     "deposit"=>0.0,
     "allow_ipn_payment"=>false,
     "delivery_info"=>nil,
     "allow_online_payment"=>false,
     "allow_online_credit_card_payment"=>false,
     "allow_online_ach_payment"=>false,
     "exchange_rate"=>0.0,
     "private_note"=>nil,
     "global_tax_calculation"=>nil,
     "sync_token"=>0,
     "billing_address"=>
     {"id"=>"572",
      "address1"=>"21 Elmcrest Drive",
      "address2"=>nil,
      "address3"=>nil,
      "address4"=>nil,
      "address5"=>nil,
      "city"=>"Chicopee",
      "country"=>"US",
      "state"=>"MA",
      "country_sub_division_code"=>"MA",
      "zipcode"=>"01013",
      "note"=>nil,
      "lat"=>nil,
      "lon"=>nil},
      "shipping_address"=>
     {"id"=>"573",
      "address1"=>"21 Elmcrest Drive",
      "address2"=>nil,
      "address3"=>nil,
      "address4"=>nil,
      "address5"=>nil,
      "city"=>"Chicopee",
      "country"=>"US",
      "state"=>"MA",
      "country_sub_division_code"=>"MA",
      "zipcode"=>"01013",
      "note"=>nil,
      "lat"=>nil,
      "lon"=>nil},
      "email"=>"marc@nurelm.com",
      "customer"=>{"name"=>"Marc Salo", "id"=>"125"},
      "class"=>{},
      "department"=>{},
      "currency"=>{"name"=>"United States Dollar", "id"=>"USD"},
      "sales_term"=>{"name"=>nil, "id"=>"3"},
      "deposit_to_account"=>{},
      "ship_method"=>{},
      "ar_account"=>{},
      "tax_detail"=>{"txn_tax_code_ref"=>nil, "total_tax"=>"0.0", "tax_lines"=>[]},
      "linked_transactions"=>[],
      "custom_fields"=>
     [{"id"=>1,
       "name"=>"Crew #",
       "type"=>"StringType",
       "string_value"=>nil,
       "boolean_value"=>nil,
       "date_value"=>nil,
       "number_value"=>nil}],
       "line_items"=>
     [
       {
         "id"=>"1",
         sku: "cup",
         "line_num" =>1,
         "description"=>"A fine cup.",
         "amount"=>0.0,
         "rate_percent"=>nil,
         "quantity"=>1.0,
         "service_date"=>nil,
         "price": 13,
         "quantity": 1
       }
     ],
      "status"=>"Paid"}
  }
  let(:prefixed_invoice) {
    {
      "id": "2",
      "class": {
      },
      "email": "jboucaud@systum.com",
      "total": 84.44,
      "qbo_id": "1403",
      "status": "Open",
      "balance": 84.44,
      "deposit": 0.0,
      "currency": {
        "id": "USD",
        "name": "United States Dollar"
      },
      "customer": {
        "id": "168",
        "name": "Systum Test"
      },
      "due_date": "2019-06-30",
      "txn_date": "2019-06-28",
      "ship_date": nil,
      "ar_account": {
      },
      "created_at": "2019-06-27 15:23:32 -0700",
      "department": {
      },
      "doc_number": "custom-2",
      "home_total": 0.0,
      "line_items": [
        {
          "id": "1",
          "amount": 78.0,
          "line_num": 1,
          "sku": "200901-NONAME",
          "description": "200901 - NONAME",
          "detail_type": "SalesItemLineDetail",
          "price": 78.0,
          "quantity": 5,
          "line_detail": {
            "item": {
              "id": "890",
              "name": "200901"
            },
            "class": {
            },
            "quantity": 1.0,
            "tax_code": {
              "id": "NON",
              "name": nil
            },
            "unit_price": 78.0,
            "price_level": {
            },
            "rate_percent": nil,
            "service_date": nil
          }
        }
      ],
      "sales_term": {
      },
      "sync_token": 0,
      "tax_detail": {
        "tax_lines": [

        ],
        "total_tax": "0.0",
        "txn_tax_code_ref": nil
      },
      "ship_method": {
      },
      "email_status": "NotSet",
      "home_balance": 0.0,
      "print_status": "NeedToPrint",
      "private_note": nil,
      "tracking_num": nil,
      "custom_fields": [
        {
          "id": 1,
          "name": "Crew #",
          "type": "StringType",
          "date_value": nil,
          "number_value": nil,
          "string_value": nil,
          "boolean_value": nil
        }
      ],
      "customer_memo": nil,
      "delivery_info": nil,
      "exchange_rate": 0.0,
      "auto_doc_number": nil,
      "billing_address": {
        "id": "1084",
        "lat": nil,
        "lon": nil,
        "city": "Plano",
        "note": nil,
        "state": "Texas",
        "country": "United States",
        "zipcode": "75024",
        "address1": "6900 Dallas Parkway",
        "address2": nil,
        "address3": nil,
        "address4": nil,
        "address5": nil,
        "country_sub_division_code": "Texas"
      },
      "shipping_address": {
        "id": "1085",
        "lat": nil,
        "lon": nil,
        "city": "Plano",
        "note": nil,
        "state": "Texas",
        "country": "United States",
        "zipcode": "75024",
        "address1": "6900 Dallas Parkway",
        "address2": nil,
        "address3": nil,
        "address4": nil,
        "address5": nil,
        "country_sub_division_code": "Texas"
      },
      "allow_ipn_payment": false,
      "deposit_to_account": {
      },
      "linked_transactions": [

      ],
      "allow_online_payment": false,
      "global_tax_calculation": nil,
      "allow_online_ach_payment": false,
      "apply_tax_after_discount": false,
      "allow_online_credit_card_payment": false
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
          "quickbooks_create_new_product": "1",
          "quickbooks_prefix": "QBO-"
        },
        invoice: invoice
      }.to_json, headers
      body = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
    end
  end

  describe "#update_invoice", vcr: { record: :new_episodes } do
    it "returns 200 and a summary" do
      post '/update_invoice', {
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
          "quickbooks_create_new_product": "1",
        },
        invoice: existing_invoice
      }.to_json, headers
      body = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
    end

    it "returns 200 when using a quickbooks_prefix" do
      skip("Getting Transaction Date Error but prefixes were finding and update correct invoice")
      post '/update_invoice', {
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
          "quickbooks_create_new_product": "1",
          "quickbooks_prefix": "custom-"
        },
        invoice: prefixed_invoice
      }.to_json, headers
      body = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
    end
  end

end
