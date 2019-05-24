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
  let(:order) {
    {
      "email": nil,
      "status": "1",
      "totals": {
        "tax": 0.0,
        "item": 173.7,
        "order": 173.7,
        "payment": 173.7,
        "discount": 0.0,
        "shipping": 0.0
      },
      "channel": "3DCart",
      "payments": [
        {
          "amount": 173.7,
          "status": "1",
          "payment_method": "Discover"
        }
      ],
      "line_items": [
        {
          "name": "1234321",
          "quantity": 1.0,
          "product_id": "1234321",
          "price": 30
        }
      ],
      "adjustments": [
        {
          "name": "Tax",
          "value": 0.0
        },
        {
          "name": "Shipping",
          "value": 0.0
        },
        {
          "name": "Discounts",
          "value": 0.0
        }
      ],
      "tax_line_items": [
        {
          "name": "Sales Tax",
          "amount": 0.0
        }
      ],
      "billing_address": {
        "city": "Chicopee",
        "phone": "800-700-1111",
        "state": "MA",
        "country": "US",
        "zipcode": "01013",
        "address1": "21 Main Drive",
        "address2": "",
        "lastname": "Salomm",
        "firstname": "Marcmm"
      },
      "three_d_cart_id": 14888,
      "shipping_address": {
        "city": "Chicopee",
        "phone": "800-700-1111",
        "state": "MA",
        "country": "US",
        "zipcode": "01013",
        "address1": "21 Main Drive",
        "address2": "",
        "lastname": "Salo",
        "firstname": "Marc"
      },
      "shipping_line_items": [
        {
          "name": "By Value",
          "amount": 0.0
        }
      ],
    }
  }
  let(:new_order) {
    {
      "email": nil,
      "status": "1",
      "totals": {
        "tax": 0.0,
        "item": 173.7,
        "order": 173.7,
        "payment": 173.7,
        "discount": 0.0,
        "shipping": 0.0
      },
      "channel": "3DCart",
      "payments": [
        {
          "amount": 173.7,
          "status": "1",
          "payment_method": "Discover"
        }
      ],
      "line_items": [
        {
          "name": "09876",
          "quantity": 1.0,
          "product_id": "09876",
          "price": 30
        }
      ],
      "adjustments": [
        {
          "name": "Tax",
          "value": 0.0
        },
        {
          "name": "Shipping",
          "value": 0.0
        },
        {
          "name": "Discounts",
          "value": 0.0
        }
      ],
      "tax_line_items": [
        {
          "name": "Sales Tax",
          "amount": 0.0
        }
      ],
      "billing_address": {
        "city": "Chicopee",
        "phone": "800-700-1111",
        "state": "MA",
        "country": "US",
        "zipcode": "01013",
        "address1": "21 Main Drive",
        "address2": "",
        "lastname": "Rogers",
        "firstname": "Steve"
      },
      "three_d_cart_id": 14888,
      "shipping_address": {
        "city": "Chicopee",
        "phone": "800-700-1111",
        "state": "MA",
        "country": "US",
        "zipcode": "01013",
        "address1": "21 Main Drive",
        "address2": "",
        "lastname": "Salo",
        "firstname": "Marc"
      },
      "shipping_line_items": [
        {
          "name": "By Value",
          "amount": 0.0
        }
      ],
    }
  }
  let(:existing_order) {
    {
      "number": 1080,
      "email": nil,
      "status": "1",
      "totals": {
        "tax": 0.0,
        "item": 173.7,
        "order": 173.7,
        "payment": 173.7,
        "discount": 0.0,
        "shipping": 0.0
      },
      "channel": "3DCart",
      "payments": [
        {
          "amount": 173.7,
          "status": "1",
          "payment_method": "Discover"
        }
      ],
      "line_items": [
        {
          "name": "1234321",
          "quantity": 1.0,
          "product_id": "1234321",
          "price": 30
        }
      ],
      "adjustments": [
        {
          "name": "Tax",
          "value": 0.0
        },
        {
          "name": "Shipping",
          "value": 0.0
        },
        {
          "name": "Discounts",
          "value": 0.0
        }
      ],
      "tax_line_items": [
        {
          "name": "Sales Tax",
          "amount": 0.0
        }
      ],
      "billing_address": {
        "city": "Chicopee",
        "phone": "800-700-1111",
        "state": "MA",
        "country": "US",
        "zipcode": "01013",
        "address1": "21 Main Drive",
        "address2": "",
        "lastname": "Salomm",
        "firstname": "Marcmm"
      },
      "three_d_cart_id": 14888,
      "shipping_address": {
        "city": "Chicopee",
        "phone": "800-700-1111",
        "state": "MA",
        "country": "US",
        "zipcode": "01013",
        "address1": "21 Main Drive",
        "address2": "",
        "lastname": "Salo",
        "firstname": "Marc"
      },
      "shipping_line_items": [
        {
          "name": "By Value",
          "amount": 0.0
        }
      ],
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "get_orders", vcr: true do
    it "returns 200 and summary with id for default configs" do
      post '/get_orders', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_since": "2019-01-13T14:50:22-08:00",
          "quickbooks_page_num": "1",
        },
      }.to_json, headers
      response = JSON.parse(last_response.body)
      p response["orders"]
      expect(last_response.status).to eq 206
      expect(response["summary"]).to be_instance_of(String)
      expect(response["orders"].count).to eq 50
    end
  end

  describe "add_order", vcr: true do
    it "returns 200 and summary with id for default configs" do
      post '/add_order', {
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
          "quickbooks_web_orders_users": "1",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_create_new_product": "0",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

    it "returns 200 when quickbooks_payment_method_name in order" do
      merged_order = order.merge({
        "quickbooks_payment_method_name": "American Express"
      })

      post '/add_order', {
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
          "quickbooks_web_orders_users": "1",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_create_new_product": "0",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": merged_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

    it "returns 200 when tax, discount, and shipping item in order" do
      merged_order = order.merge({
          "quickbooks_tax_item": "product_tax",
          "quickbooks_discount_item": "discount",
          "quickbooks_shipping_item": "shipping",
      })

      post '/add_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_track_inventory": "1",
          "quickbooks_account_name": "Sales of Product Income",
          "quickbooks_web_orders_users": "1",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_create_new_product": "0",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": merged_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

    it "returns 200 when deposit to account name and account name" do
      merged_order = order.merge({
        "quickbooks_deposit_to_account_name": "Undeposited Funds",
        "quickbooks_account_name": "Sales of Product Income",
      })

      post '/add_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_track_inventory": "1",
          "quickbooks_web_orders_users": "1",
          "quickbooks_tax_item": "product_tax",
          "quickbooks_discount_item": "discount",
          "quickbooks_shipping_item": "shipping",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_create_new_product": "0",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": merged_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

    it "returns 200 when inventory and cogs account in order" do
      order["line_items"] = [
        {
          "name": "new item 2",
          "quantity": 1.0,
          "sku": "new-item-sku-2",
          "price": 30
        }
      ]
      order["placed_on"] = Time.now
      merged_order = order.merge({
        "quickbooks_inventory_account": "Inventory Asset",
        "quickbooks_cogs_account": "Cost of Goods Sold"
      })

      post '/add_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_track_inventory": "1",
          "quickbooks_web_orders_users": "1",
          "quickbooks_tax_item": "product_tax",
          "quickbooks_discount_item": "discount",
          "quickbooks_shipping_item": "shipping",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_create_new_product": "1",
          "quickbooks_deposit_to_account_name": "Undeposited Funds",
          "quickbooks_account_name": "Sales of Product Income",
        },
        "order": merged_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

    it "returns 200 when track_inventory, create_new_customers, and create_new_product in order" do
      merged_order = new_order.merge({
        "quickbooks_track_inventory": "1",
        "quickbooks_create_new_product": "1",
        "quickbooks_create_new_customers": "1"
      })

      post '/add_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_web_orders_users": "0",
          "quickbooks_tax_item": "product_tax",
          "quickbooks_discount_item": "discount",
          "quickbooks_shipping_item": "shipping",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_deposit_to_account_name": "Undeposited Funds",
          "quickbooks_account_name": "Sales of Product Income",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": merged_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

  end

  describe "update_order", vcr: true do
    it "returns 200 and summary with id for default configs" do
      post '/update_order', {
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
          "quickbooks_web_orders_users": "1",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_create_new_product": "0",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": existing_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end

    it "returns 200 and when setting quickbooks_create_or_update" do
      merged_order = existing_order.merge({
        "number": "404-does_not_exist"
      })

      post '/update_order', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_create_or_update": "1",
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_tax_item": "product_tax",
          "quickbooks_discount_item": "discount",
          "quickbooks_shipping_item": "shipping",
          "quickbooks_track_inventory": "1",
          "quickbooks_account_name": "Sales of Product Income",
          "quickbooks_web_orders_users": "1",
          "quickbooks_payment_method_name": "[{\"shopify_payments\":\"MasterCard\", \"PayPal\":\"PayPal\", \"Visa\":\"Visa\", \"Discover\":\"Discover\", \"American Express\":\"American Express\", \"None\":\"Cash\", \"Cash\":\"Cash\", \"Money Order\":\"Cash\", \"Check Payments\":\"Cash\"}]",
          "quickbooks_inventory_account": "Inventory Asset",
          "quickbooks_create_new_product": "0",
          "quickbooks_cogs_account": "Cost of Goods Sold"
        },
        "order": merged_order
      }.to_json, headers
      response = JSON.parse(last_response.body)
      expect(last_response.status).to eq 200
      expect(response["summary"]).to be_instance_of(String)
    end
  end

end
