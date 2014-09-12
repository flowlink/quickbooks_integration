module Factories
  class << self
    def config
      {
        'quickbooks_access_token'          => "qyprdhjEBfA2BI8sD7fWVPH4wL9esaKrYeWLosiPBir3pa5j",
        'quickbooks_access_secret'         => "yU7RtuM1Lot803jkkCfcyV9GePoNZGnZO8nRbBxo",
        'quickbooks_income_account'        => "Sales of Product Income",
        'quickbooks_realm'                 => "835973000",
        'quickbooks_inventory_account'     => "Inventory Asset",
        'quickbooks_deposit_to_account_name' => "Inventory Asset",
        'quickbooks_cogs_account'          => "Cost of Goods Sold",
        'quickbooks_payment_method_name' => [{ "visa" => "Discover" }],
        'quickbooks_account_name' => "Inventory Asset",
        'quickbooks_poll_stock_timestamp' => '2014-04-13T18:48:56.001Z'
      }
    end

    def order_changes(args = {})
      {
        "totals"=> {
          "item"=> 119.94,
          "adjustment"=> 15,
          "tax"=> 5,
          "shipping"=> 0,
          "payment"=> 114.95,
          "order"=> 134.94
        },
        "line_items"=> [
          {
            "name"=> "Spree Baseball Jersey",
            "sku"=> "SPR-00001",
            "external_ref"=> "",
            "quantity"=> 3,
            "price"=> 19.99,
            "variant_id"=> 8,
            "options"=> {}
          },
          {
            "name"=> "Ruby on Rails Baseball Jersey",
            "sku"=> "ROR-00004",
            "external_ref"=> "",
            "quantity"=> 3,
            "price"=> 19.99,
            "variant_id"=> 20,
            "options"=> {
                "tshirt-color"=> "Red",
                "tshirt-size"=> "Medium"
            }
          }
        ]
      }.merge(args)
    end

    def order(args = {})
      {
          "number"=> "R181807170",
          "channel"=> "spree",
          "email"=> "spree@example.com",
          "currency"=> "USD",
          "placed_on"=> "2013-07-30T19:19:5Z",
          "updated_at"=> "2013-07-30T20:08:39Z",
          "status"=> "complete",
          "totals"=> {
              "item"=> 99.95,
              "adjustment"=> 15,
              "tax"=> 5,
              "shipping"=> 0,
              "payment"=> 114.95,
              "order"=> 114.95
          },
          "line_items"=> [
              {
                  "name"=> "Spree Baseball Jersey",
                  "sku"=> "SPR-00001",
                  "external_ref"=> "",
                  "quantity"=> 2,
                  "price"=> 19.99,
                  "variant_id"=> 8,
                  "options"=> {}
              },
              {
                  "name"=> "Ruby on Rails Baseball Jersey",
                  "sku"=> "ROR-00004",
                  "external_ref"=> "",
                  "quantity"=> 3,
                  "price"=> 19.99,
                  "variant_id"=> 20,
                  "options"=> {
                      "tshirt-color"=> "Red",
                      "tshirt-size"=> "Medium"
                  }
              }
          ],
          "adjustments"=> [
              {
                  "name"=> "Shipping",
                  # drop this key once cassets are replayed
                  "originator_type"=> "Spree::ShippingMethod",
                  "value"=> "5.0"
              },
              {
                  "name"=> "Shipping",
                  "originator_type"=> "Spree::ShippingMethod",
                  "value"=> "5.0"
              },
              {
                  "name"=> "North America 5.0",
                  "originator_type"=> "Spree::TaxRate",
                  "value"=> "5.0"
              }
          ],
          "shipping_address"=> {
              "firstname"=> "Brian",
              "lastname"=> "Quinn",
              "address1"=> "7735 Old Georgetown Rd",
              "address2"=> "",
              "zipcode"=> "20814",
              "city"=> "Bethesda",
              "state"=> "Maryland",
              "country"=> "US",
              "phone"=> "555-123-456"
          },
          "billing_address"=> {
              "firstname"=> "Brian",
              "lastname"=> "Quinn",
              "address1"=> "7735 Old Georgetown Rd",
              "address2"=> "",
              "zipcode"=> "20814",
              "city"=> "Bethesda",
              "state"=> "Maryland",
              "country"=> "US",
              "phone"=> "555-123-456"
          },
          "payments"=> [
              {
                  "number"=> 6,
                  "status"=> "completed",
                  "amount"=> 5,
                  "payment_method"=> "visa"
              },
              {
                  "number"=> 5,
                  "status"=> "completed",
                  "amount"=> 109.95,
                  "payment_method"=> "visa"
              }
          ],
          "shipments"=> [
              {
                  "number"=> "H184070692",
                  "cost"=> 5,
                  "status"=> "shipped",
                  "stock_location"=> nil,
                  "shipping_method"=> "UPS Ground (USD)",
                  "tracking"=> nil,
                  "updated_at"=> nil,
                  "shipped_at"=> "2013-07-30T20:08:38Z",
                  "items"=> [
                      {
                          "name"=> "Spree Baseball Jersey",
                          "sku"=> "SPR-00001",
                          "external_ref"=> "",
                          "quantity"=> 1,
                          "price"=> 19.99,
                          "variant_id"=> 8,
                          "options"=> {}
                      },
                      {
                          "name"=> "Ruby on Rails Baseball Jersey",
                          "sku"=> "ROR-00004",
                          "external_ref"=> "",
                          "quantity"=> 1,
                          "price"=> 19.99,
                          "variant_id"=> 20,
                          "options"=> {
                              "tshirt-color"=> "Red",
                              "tshirt-size"=> "Medium"
                          }
                      }
                  ]
              },
              {
                  "number"=> "H532961116",
                  "cost"=> 5,
                  "status"=> "ready",
                  "stock_location"=> nil,
                  "shipping_method"=> "UPS Ground (USD)",
                  "tracking"=> "4532535354353452",
                  "updated_at"=> nil,
                  "shipped_at"=> nil,
                  "items"=> [
                      {
                          "name"=> "Ruby on Rails Baseball Jersey",
                          "sku"=> "ROR-00004",
                          "external_ref"=> "",
                          "quantity"=> 2,
                          "price"=> 19.99,
                          "variant_id"=> 20,
                          "options"=> {
                              "tshirt-color"=> "Red",
                              "tshirt-size"=> "Medium"
                          }
                      },
                      {
                          "name"=> "Spree Baseball Jersey",
                          "sku"=> "SPR-00001",
                          "external_ref"=> "",
                          "quantity"=> 1,
                          "price"=> 19.99,
                          "variant_id"=> 8,
                          "options"=> {}
                      }
                  ]
              }
          ]
      }.merge(args)
    end

    def return_authorization
      JSON.parse(IO.read("#{File.dirname(__FILE__)}/messages/return_authorization.json")).with_indifferent_access
    end

    def new_credit_memo
      JSON.parse(IO.read("#{File.dirname(__FILE__)}/messages/new_credit_memo.json")).with_indifferent_access
    end

    def add_product
      JSON.parse(IO.read("#{File.dirname(__FILE__)}/messages/add_product.json")).with_indifferent_access
    end

    def add_order
      JSON.parse(IO.read("#{File.dirname(__FILE__)}/messages/add_order.json")).with_indifferent_access
    end

    def legacy_product
      JSON.parse(IO.read("#{File.dirname(__FILE__)}/messages/legacy_product.json")).with_indifferent_access
    end
  end
end
