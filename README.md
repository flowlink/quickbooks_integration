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
- quickbooks_poll_stock_timestamp - This is a timestamp => **Required**

/get_customers
- quickbooks_since - This is a timestamp => **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed => **Required**

/get_products
- quickbooks_since - This is a timestamp => **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed => **Required**

/add_product
- quickbooks_income_account - Name of the income account associated with the item we're creating
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required**
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account - Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_track_inventory is set to true or '1'**

/update_product
- quickbooks_income_account - Name of the income account associated with the item we're creating
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required**
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account - Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the item if it is not found in QuickBooks => **Required**

/add_order
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online => **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Order payload field takes precedence over workflow parameter. Defaults to "Web User" if neither order payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Order is not found  => **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Order are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which Sales Receipts should be deposited (normally Undeposited Funds)

/update_order
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the Order if it is not found in QuickBooks => **Required**
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online => **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Order payload field takes precedence over workflow parameter. Defaults to "Web User" if neither order payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Order is not found  => **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Order are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which Sales Receipts should be deposited (normally Undeposited Funds)

/add_invoice
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Invoice payload field takes precedence over workflow parameter. Defaults to "Web User" if neither invoice payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Invoice is not found  => **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Invoice are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which payments from Invoices should be deposited (normally Undeposited Funds)
- quickbooks_ar_account_name - The Account Name used for your Accounts Receivable account in QuickBooks Online

/update_invoice
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the Invoice if it is not found in QuickBooks => **Required**
- quickbooks_discount_item- Name of the Item in QuickBooks used for adding discount amount as a line item => **Required**
- quickbooks_shipping_item - Name of the Item in QuickBooks used for adding shipping amount as a line item => **Required**
- quickbooks_tax_item - Name of the Item in QuickBooks used for adding tax amount as a line item => **Required**
- quickbooks_web_orders_users - Boolean used to determine if FlowLink should group customers under a general customer instead of creating new customers => **Required**
- quickbooks_generic_customer_name - Name of the Customer used when rolling up customers into a general QuickBooks Online customer. Invoice payload field takes precedence over workflow parameter. Defaults to "Web User" if neither invoice payload or parameter are set. Unused if quickbooks_web_orders_users is false.
- quickbooks_create_new_customers - Boolean used to determine if FlowLink should create new customers if the customer on the Invoice is not found  => **Required**
- quickbooks_create_new_product - Boolean used to determine if FlowLink should create new items if any line items on the Invoice are not found  => **Required**
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required if quickbooks_create_new_product is true**
- quickbooks_account_name - Name of the income account associated with the item we're creating
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account- Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_create_new_product is true AND quickbooks_track_inventory is set to true or '1'**
- quickbooks_deposit_to_account_name - The Account Name in which payments from Invoices should be deposited (normally Undeposited Funds)
- quickbooks_ar_account_name - The Account Name used for your Accounts Receivable account in QuickBooks Online

/add_payment
- quickbooks_payment_method_name - Mapping for payment methods in QuickBooks Online => **Required**
- allow_unapplied_payment - If this parameter is set, payments that have no transaction ID on them will still be created in QBO. They will have no related transaction.


# Error Codes:
001 - QuickBooks Journal Entry not found
002 - Customer field cannot be empty on Accounts Receivable Journal Entry
003 - Customer field was not empty in Journal Entry, but Customer was not found in QuickBooks
004 - Class field was not empty in Journal Entry, but Class was not found in QuickBooks
005 - No Account was found in QuickBooks for the given Account Name


# Extra Information
- When creating an Inventory product, the `inventory_start_date` of the product must be on or prior to any order/invoice dates that the product already exists on. The `inventory_start_date` defaults to now if you're attempting to create the product on the fly during the order sync. When using the product sync, you can update/add a field on the product called `inventory_start_date` and set it to the correct date and time.
- When adding orders or invoices, FlowLink uses the product SKU as the identifier when attempting to locate line items on the order. If the SKU field is empty, FlowLink will throw an error letting you know order line items must contain SKUs
- QuickBooks API does not offer the creation of Bundled Items. This must be done manually through the app.
- When adding SalesReceipts, we don't currently have a way to add bundled items to the receipt
- When attempting to run the product sync, each item should have a unique name as well as a unique SKU
- QuickBooks uses Categories to handle hierarchies. If you'd like to add a Category to one of your products, the product sync can handle that. We only support 1 level of hierarchy currently. To specify the Category under which the product live, set the field `parent_name` to the name of the Category in QuickBooks. If FlowLink cannot find a Category with that name, it will create a new Category and put the product under the newly created Category.
- Many clients find that their eCommerce solution can break out tax, shipping, or discounts into multiple items. To accomodate this, FlowLink breaks out tax, shipping, or discounts into multiple line items on SalesReceipts and Invoices. We achieve this by using a product for each of these. So, before running an Order or Invoice sync, you'll need to create a Non Inventory product. Name the item and give it a SKU (The SKU is the name FlowLink needs). We recommend naming the item and SKU the exact same thing. For instance if you were to create a tax item, we would recommend => Item Name: 'Tax', SKU: 'Tax'. Check the "I sell this product/service to my customers" box. Set the correct Income Account. Make sure the "I purchase this product/service from a vendor" is unchecked.
- When running the Order sync workflow, FlowLink needs to be able to map the payment methods contained in your orders to the payment methods within QuickBooks. To do this, we just need a list of all possible payment methods that could be on an Order and which payment method you would like QuickBooks to select when it's on an order. Please be sure spelling and capitalization is accurate. Note: many payment methods will likely map to themselves: Cash -> Cash, but some may have small discrepancies: Cash -> cash.
- When running the product sync, we'll need to create separate workflows for Inventory and Non-Inventory products. We'll also need to create separate workflows for products associated with different account within QuickBooks

# About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
