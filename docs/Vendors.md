# /get_vendors
- quickbooks_since - Timestamp that tells the integration to retrieve all vendors that are new or have been updated since this timestamp => **Required**
- page - Number used for paginating requests. Defaults to 1
- per_page - Number used to specify the amount of vendors to retrieve for each request. Defaults to 50

# /add_vendor
- quickbooks_vendor_name - You can specify the name of the vendor as a parameter rather than have the integration parse the payload

# /update_vendor
- quickbooks_vendor_name - You can specify the name of the vendor as a parameter rather than have the integration parse the payload
- quickbooks_create_new_vendors - Boolean used to determine if FlowLink should create a new vendor if they are not found  => **Required**


# Notes
The /add_vendor endpoint does not support updating vendors. You can use the /update_vendor endpoint to both add and update at once