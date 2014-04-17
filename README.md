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
| quickbooks_deposit_to_account_name | Default to Undeposited Funds Account (not required) | Prepaid Expenses |
| quickbooks_shipping_item | Quickbooks Item SKU to use for shipping line items (required) | SKU-SHIPPING |
| quickbooks_tax_item | Quickbooks Item SKU to use for tax line items (required) | SKU-TAX |
| quickbooks_discount_item | Quickbooks Item SKU to use for discount line items (required) | SKU-DISCOUNT |
| quickbooks_account_name | Quickbooks Income Account name for the items (required) | false |
| quickbooks_web_orders_users | Check to use 'Web User' as customer name for all SalesReceipts | false |
| quickbooks_payment_method_name | Mapping from store payment method names to Quickbooks payment method names (required) |{ "visa" => "credit-card", "master-card" => "credit-card" }|

### Product webhooks

Push Products as Items into Quickbooks.

By setting `quickbooks_track_inventory` `true` you need to provide a valid
Income Account and Cost of Goods Sold account.

#### Parameters

| Name | Value | Example |
| :----| :-----| :------ |
| quickbooks_inventory_account | Inventory Account (required) | Inventory Asset |
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
