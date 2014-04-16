# Quickbooks Online Integration

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [Quickbooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

## Authorize with oAuth
To get started, you will need to connect the hub to your Quickbooks Online (QBO) account. To do this please visit the [Connect Quickbooks with oAUTH](http://spreecommerce.com/quickbooks) page. When you have authorized the hub you will see a page that contains the access token, the access sercret and realm. You will need those when you configure the Quickbooks Online Integration in your storefront. 

## Services

#### Connection parameters

| Name | Value | Example |
| :----| :-----| :------ |
| quickbooks_access_token | Quickbooks oAUTH Access Token |Aqws3958dhdjwb39|
| quickbooks_access_secret | Quickbooks oAUTH Access Secret |dj20492dhjkdjeh2838w7|
| quickbooks_realm | Quickbooks oAUTH Realm |82341|

### Order webhooks

Push Orders as SalesReceipts into Quickbooks.

Shipping, Tax, Coupon and Discount values from Spree will be treated as line-items and imported as Non-Inventory items.

It's possible to provide a payment method mapping to translate the types of methods used in yout store to those of Quickbooks.

Also supports the following option:

 - **Web Order User:** Check if you want to use 'Web User' as customer for all SalesReceipts.

#### parameters

| Name | Value | Example |
| :----| :-----| :------ |
| quickbooks_deposit_to_account_name | Quickbooks account name to book the SalesReceipt in. | Prepaid Expenses |
| quickbooks_payment_method_name | Mapping from Spree payment method names to Quickbooks payment method names |{ "visa" => "credit-card", "master-card" => "credit-card" }|
| quickbooks_shipping_item | Quickbooks Item SKU to use for shipping line items | SKU-SHIPPING |
| quickbooks_tax_item | Quickbooks Item SKU to use for tax line items |SKU-TAX|
| quickbooks_discount_item | Quickbooks Item SKU to use for discount line items |SKU-DISCOUNT|
| quickbooks_account_name | Quickbooks Income Account name for the items | Sales of Product Income |
| quickbooks_web_orders_users | Check to use 'Web User' as customer name for all SalesReceipts | false|

### Product webhooks

Push Products as Items into Quickbooks supporting the following options:

 - **Inventory/Non-Inventory:** If you want to export products as Inventory items, enable this option and provide the *Cost of Goods Sold* and *Income* accounts.
 - **Import Variants as Sub-Items:** Spree products' variants can be imported as sub-items by Quickbooks, in order to mantain the hierarchical relationship.

The specified accounts must exist in Quickbooks.

#### Parameters

| Name | Value | Example |
| :----| :-----| :------ |
| quickbooks_inventory_costing | Inventory/Non-Inventory Item Option | true |
| quickbooks_inventory_account | Inventory Account | Inventory Asset |
| quickbooks_cogs_account | Cost of Goods Sold Account | Cost Of Goods Sold |
| quickbooks_income_account | Income Account | Sales of Product Income |
| quickbooks_track_inventory | Track inventory | false |

### Return webhooks

Creates a credit memo on github. No specific parameters needed.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
