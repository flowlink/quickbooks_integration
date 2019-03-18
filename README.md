# QuickBooks Online Integration

## Overview

[QuickBooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [QuickBooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

Please visit the [wiki](https://github.com/flowlink/quickbooks_integration/wiki)
for further info on how to connect this integration.

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product. With this integration you can perform the following functions:

* Send orders to QuickBooks as Sales Receipts
* Send products to QuickBooks as Items
* Send returns to QuickBooks as Credit Memo
* Poll for inventory stock levels in QuickBooks

### 21 Character limit on Order numbers.

If your having problems with it, this transform should help:
```javascript
//nomustache
payload.order.number = payload.order.number.substring(0, 21);
```

## Development

### Generate OAuth Keys

Create an app here: https://developer.intuit.com/v2/ui#/app/dashboard and generate your oauth keys.

### Environment Variables
For Production
Copy "sample.env" to "prod.env" and fill out the following variables:

`QB_CONSUMER_KEY` - OAuth consumer key for production
`QB_CONSUMER_SECRET` -  OAuth token for production

For Development
Copy "sample.env" to ".env" and ".dev.env" and fill out the following variables:

`QB_CONSUMER_KEY` - OAuth consumer key for development
`QB_CONSUMER_SECRET` -  OAuth token for development

# Starting Application

`bundle exec unicorn` -- Starts application on port 8080

## Connection Parameters
```
"quickbooks_access_secret": "",
"quickbooks_realm": "",
"quickbooks_access_token": ""
```
- quickbooks_access_secret: Secret from Intuit
- quickbooks_realm: QuickBooks realm
- quickbooks_access_token: Access token from Intuit

## Endpoints
/get_inventory
- quickbooks_poll_stock_timestamp - This is a timestamp **Required**

/get_customers
- quickbooks_since - This is a timestamp **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed **Required**

/get_products
- quickbooks_since - This is a timestamp **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed **Required**

/add_product
- quickbooks_income_account - Name of the income account associated with the item we're creating
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory **Required**
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account **Required if quickbooks_track_inventory is set to true or '1'**

/update_product
- quickbooks_income_account - Name of the income account associated with the item we're creating
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory **Required**
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account - Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the item if it is not found in QuickBooks **Required**

/add_order
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item **Required**
- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer called "Web User" instead of creating new customers **Required**
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Order is not found  **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Order are not found  **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which Sales Receipts should be deposited (normally Undeposited Funds)

/update_order
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the Order if it is not found in QuickBooks **Required**
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item **Required**
- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer called "Web User" instead of creating new customers **Required**
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Order is not found  **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Order are not found  **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which Sales Receipts should be deposited (normally Undeposited Funds)

/add_invoice
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer called "Web User" instead of creating new customers **Required**
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Invoice is not found  **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Invoice are not found  **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which payments from Invoices should be deposited (normally Undeposited Funds)
- quickbooks_ar_account_name - The Account Name used for your Accounts Receivable account in QuickBooks Online

/update_invoice
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the Invoice if it is not found in QuickBooks **Required**
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer called "Web User" instead of creating new customers **Required**
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Invoice is not found  **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Invoice are not found  **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which payments from Invoices should be deposited (normally Undeposited Funds)
- quickbooks_ar_account_name - The Account Name used for your Accounts Receivable account in QuickBooks Online


# Error Codes:
001 - QuickBooks Journal Entry not found
002 - Customer field cannot be empty on Accounts Receivable Journal Entry
003 - Customer field was not empty in Journal Entry, but Customer was not found in QuickBooks
004 - Class field was not empty in Journal Entry, but Class was not found in QuickBooks
005 - No Account was found in QuickBooks for the given Account Name

# About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
