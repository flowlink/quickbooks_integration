# QuickBooks Online Integration

## Overview

[QuickBooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [QuickBooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

Please visit the [wiki](https://github.com/flowlink/quickbooks_integration/wiki)
for further info on how to connect this integration.

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product. With this integration you can perform the following functions:

* Send Orders to QuickBooks as Sales Receipts
* Get Sales Receipts from QuickBooks as Orders
* Cancel Sales Receipts in QuickBooks
* Send Invoices to QuickBooks as Invoices
* Get Invoices from QuickBooks as Invoices
* Send Products to QuickBooks as Items
* Get Items from QuickBooks as Products
* Send Customers to QuickBooks as Customers
* Get Customers from QuickBooks as Customers
* Send Vendors to QuickBooks as Vendors
* Get Vendors from QuickBooks as Vendors
* Send Purchase Orders to QuickBooks as Purchase Orders
* Send Bills to QuickBooks as Bills
* Send Payments to QuickBooks as Payments and relate them to a specific Invoice
* Get Payments from QuickBooks as Payments
* Send Returns to QuickBooks as Credit Memo
* Poll for Inventory stock levels in QuickBooks
* Set Inventory stock levels in QuickBooks
* Send Journal Entries to QuickBooks as Journal Entries
* Delete Journal Entries in QuickBooks

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

### Starting Application

* Install [Docker](https://docs.docker.com/v17.09/engine/installation/) and [Docker-Compose](https://docs.docker.com/compose/install/)

* Run `scripts/run_local.sh` for local work

### Connection Parameters

```json
"quickbooks_access_secret": "Access Secret from Intuit",
"quickbooks_realm": "QuickBooks realm",
"quickbooks_access_token": "Access Token from Intuit"
"quickbooks_sandbox": "1"
```

Note: "quickbooks_sandbox" is not required and defaults to prodcution accounts. Set to "1" if you'd like to access a sandbox account

### Finding a customer in QBO

Possible params used:

```json
"quickbooks_web_orders_users": "0 or 1",
"quickbooks_generic_customer_name": "Name in QBO to use for Grouped/Generic Customer - defaults to 'Web Orders'",
"multiple_email_fallback": "Special set of values can be used here",
"quickbooks_create_new_customers": "0 or 1"
```

There is a set process for looking for a customer in QBO:

1. Using a "Rolled up" customer or Generic customer

    If `quickbooks_web_orders_users == "1" && order[:customer][:is_b2b] == false`, we check the `quickbooks_generic_customer_name` in the following order

    * `order[:customer][:quickbooks_generic_customer_name]`
    * `order[:quickbooks_generic_customer_name]`
    * `config[:quickbooks_generic_customer_name]`
    * Use "Web Orders" as the Customer Name

    We search QBO using the name from above. If found, we use that customer. If not found and `order[:customer]` is not nil...

2. Finding an existing customer

    * Find the customer by QBO ID if `order[:customer][:qbo_id]` exists. If it does not exist...
    * Search by name using `order[:customer][:name]`. If not found...
    * Seach by email using `order[:customer][:email]`. If multiple email entries, we raise an error unless `config[:multiple_email_fallback]` is set.

    The `multiple_email_fallback` parameter can be used on Add/Update Order, Add/Update Invoice, and Add/Update Customer. NOTE: This param is only used when the customer object is on an order. If order[:customer] does not exist, this value is not used.
    Multiple Email Fallback can be set with the following values:

    * "last_updated" => When set with this value, the integration will return the customer that has been most recently been updated based on the `last_updated_time` field

3. Creating a new customer

    If the above 2 options don't yield any customers, we check the `quickbooks_create_new_customers` parameter. NOTE: we default this to true for older customers using FlowLink.
    If the value is set to "1" or it's not set on the workflow at all, we create a new customer.

### Endpoints

[Order Endpoints](./docs/Orders.md)  
[Invoice Endpoints](./docs/Invoices.md)  
[Product Endpoints](./docs/Products.md)  
[Vendor Endpoints](./docs/Vendors.md)  
[Customer Endpoints](./docs/Customers.md)  
[Purchase Order Endpoints](./docs/PurchaseOrders.md)  
[Inventory Endpoints](./docs/Inventory.md)  
[Bill Endpoints](./docs/Bills.md)  
[Payment Endpoints](./docs/Payments.md)  

### Error Codes

001 - QuickBooks Journal Entry not found
002 - Customer field cannot be empty on Accounts Receivable Journal Entry
003 - Customer field was not empty in Journal Entry, but Customer was not found in QuickBooks
004 - Class field was not empty in Journal Entry, but Class was not found in QuickBooks
005 - No Account was found in QuickBooks for the given Account Name

### Extra Information

* When creating an Inventory product, the `inventory_start_date` of the product must be on or prior to any order/invoice dates that the product already exists on. The `inventory_start_date` defaults to now if you're attempting to create the product on the fly during the order sync. When using the product sync, you can update/add a field on the product called `inventory_start_date` and set it to the correct date and time.
* When adding orders or invoices, FlowLink uses the product SKU as the identifier when attempting to locate line items on the order. If the SKU field is empty, FlowLink will throw an error letting you know order line items must contain SKUs
* When attempting to run the product sync, each item should have a unique name as well as a unique SKU
* QuickBooks uses Categories to handle hierarchies. If you'd like to add a Category to one of your products, the product sync can handle that. We only support 1 level of hierarchy currently. To specify the Category under which the product live, set the field `parent_name` to the name of the Category in QuickBooks. If FlowLink cannot find a Category with that name, it will create a new Category and put the product under the newly created Category.
* Many clients find that their eCommerce solution can break out tax, shipping, or discounts into multiple items. To accomodate this, FlowLink breaks out tax, shipping, or discounts into multiple line items on SalesReceipts and Invoices. We achieve this by using a product for each of these. So, before running an Order or Invoice sync, you'll need to create a Non Inventory product. Name the item and give it a SKU (The SKU is the name FlowLink needs). We recommend naming the item and SKU the exact same thing. For instance if you were to create a tax item, we would recommend => Item Name: 'Tax', SKU: 'Tax'. Check the "I sell this product/service to my customers" box. Set the correct Income Account. Make sure the "I purchase this product/service from a vendor" is unchecked.
* When running the Order sync workflow, FlowLink needs to be able to map the payment methods contained in your orders to the payment methods within QuickBooks. To do this, we just need a list of all possible payment methods that could be on an Order and which payment method you would like QuickBooks to select when it's on an order. Please be sure spelling and capitalization is accurate. Note: many payment methods will likely map to themselves: Cash -> Cash, but some may have small discrepancies: Cash -> cash.
* When running the product sync, we'll need to create separate workflows for Inventory and Non-Inventory products. We'll also need to create separate workflows for products associated with different account within QuickBooks
* The QuickBooks API does not allow us to associate a Bill coming into QuickBooks with a related Transaction. Once a Bill is created using FlowLink, a manual step is needed to associate the Bill with the related Purchase Order

## About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)
