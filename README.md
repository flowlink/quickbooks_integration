# Quickbooks Online Integration

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [Quickbooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

## Authorize with oAuth
To get started, you will need to connect the hub to your Quickbooks Online (QBO) account. To do this please visit the [Connect Quickbooks with oAUTH](http://spreecommerce.com/quickbooks) page. When you have authorized the hub you will see a page that contains the access token, the access sercret and realm. You will need those when you configure the Quickbooks Online Integration in your storefront. 

## Services

### Product Persist

Exports products from Spree to Quickbooks supporting the following options:

 - **Inventory/Non-Inventory:** If you want to export products as Inventory items, enable this option and provide the *Cost of Goods Sold* and *Income* accounts.
 - **Import Variants as Sub-Items:** Spree products' variants can be imported as sub-items by Quickbooks, in order to mantain the hierarchical relationship.

The specified accounts must exist in Quickbooks.

#### Parameters

| Name | Value | Example |
| :----| :-----| :------ |
| quickbooks.access_token | oAUTH Access Token | Aqws3958dhdjwb39 |
| quickbooks.access_secret | oAUTH Access Secret Key | dj20492dhjkdjeh2838w7 |
| quickbooks.realm | The realm code that QBO need | 82341 |
| quickbooks.inventory_costing | Inventory/Non-Inventory Item Option | true |
| quickbooks.inventory_account | Inventory Account | Inventory Asset |
| quickbooks.cogs_account | Cost of Goods Sold Account | Cost Of Goods Sold |
| quickbooks.income_account | Income Account | Sales of Product Income |
| quickbooks.variants_as_sub_items | Import Variants as Sub-Items Option | true |

#### Notifications

Product was imported into Quickbooks:
```json
{
  "message_id":"52263b13b43957220e004c1a",
  "notifications":
    [{
      "level": "info",
      "subject": "Product SKU-123 imported to Quickbooks",
      "description": "Product SKU-123 imported to Quickbooks"
    }]
}
```

Product was updated into Quickbooks:
```json
{
  "message_id":"52263b13b423957220e004c2b",
  "notifications":
    [{
      "level": "info",
      "subject": "Product SKU-123 updated on Quickbooks",
      "description": "Product SKU-123 updated on Quickbooks"
    }]
}
```

Specified account was not found into Quickbooks:
```json
{
  "message_id":"52263b13b423957220e004c2b",
  "notifications":
    [{
      "level": "info",
      "subject": "No Account 'Income Account' defined in service",
      "description": "No Account 'Income Account' defined in service"
    }]
}
```

