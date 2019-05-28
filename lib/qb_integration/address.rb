module QBIntegration
  module Address
    def self.build(order_address)
      address = Quickbooks::Model::PhysicalAddress.new
      address.line1   = hash_or_empty order_address, 'address1'
      address.line2   = hash_or_empty order_address, 'address2'
      address.city    = hash_or_empty order_address, 'city'
      address.country = hash_or_empty order_address, 'country'
      address.country_sub_division_code = hash_or_empty order_address, 'state'
      address.postal_code = hash_or_empty order_address, 'zipcode'

      address
    end

    def self.hash_or_empty(hash, key)
      value = hash.nil? ? '' : hash[key]
    end

    def self.as_flowlink_hash(qbo_address)
      {
        address1: qbo_address.line1,
        address2: qbo_address.line2,
        city: qbo_address.city,
        state: qbo_address.country_sub_division_code,
        country: qbo_address.country,
        zipcode: qbo_address.postal_code
      }.compact
    end
  end
end
