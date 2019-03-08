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
- quickbooks_poll_stock_timestamp

/add_product
- quickbooks_income_account
- quickbooks_track_inventory
- quickbooks_inventory_account
- quickbooks_cogs_account

/update_product
- quickbooks_income_account
- quickbooks_track_inventory
- quickbooks_inventory_account
- quickbooks_cogs_account

/add_order
- quickbooks_discount_item
- quickbooks_shipping_item
- quickbooks_tax_item
- quickbooks_web_orders_users
- quickbooks_track_inventory
- quickbooks_payment_method_name
- quickbooks_account_name
- quickbooks_deposit_to_account_name
- quickbooks_create_new_customers

/update_order
- quickbooks_create_or_update
- quickbooks_discount_item
- quickbooks_shipping_item
- quickbooks_tax_item
- quickbooks_web_orders_users
- quickbooks_track_inventory
- quickbooks_payment_method_name
- quickbooks_account_name
- quickbooks_deposit_to_account_name
- quickbooks_create_new_customers

/add_invoice
- quickbooks_discount_item
- quickbooks_shipping_item
- quickbooks_tax_item
- quickbooks_web_orders_users
- quickbooks_track_inventory
- quickbooks_account_name
- quickbooks_deposit_to_account_name
- quickbooks_create_new_customers

/update_invoice
- quickbooks_create_or_update
- quickbooks_discount_item
- quickbooks_shipping_item
- quickbooks_tax_item
- quickbooks_web_orders_users
- quickbooks_track_inventory
- quickbooks_account_name
- quickbooks_deposit_to_account_name
- quickbooks_create_new_customers

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
