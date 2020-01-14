# Product Endpoints

## /add_product

- quickbooks_income_account - Name of the income account associated with the item we're creating
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required**
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account - Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_track_inventory is set to true or '1'**

## /update_product

- quickbooks_income_account - Name of the income account associated with the item we're creating
- quickbooks_track_inventory - Boolean used to determine if the item we're creating is of Type Inventory => **Required**
- quickbooks_inventory_account - Name of the account used for your inventory tracking (usually Inventory Asset) => **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_cogs_account - Name of the Cost of Goods Sold account (usually Cost of Goods Sold) associated with the item => **Required if quickbooks_track_inventory is set to true or '1'**
- quickbooks_create_or_update - Boolean used to determine if FlowLink should create the item if it is not found in QuickBooks => **Required**

## /get_products

- quickbooks_since - This is a timestamp => **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed => **Required**
