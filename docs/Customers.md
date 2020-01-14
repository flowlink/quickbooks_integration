# Customer Endpoints

## /get_customers

- quickbooks_since - This is a timestamp => **Required**
- quickbooks_page_num - Integer. Should be set to 1 to start. The Integration will update and reset as needed => **Required**

## /add_customer

No Parameters

## /update_customer

- create_or_update - Creates a new customer if one doesn't exists yet and if this value is set to "1"

## Notes

The /add_customer endpoint _will_ create and update customers