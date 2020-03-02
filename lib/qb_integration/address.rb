module QBIntegration
  module Address
    def self.build(order_address)
      address = Quickbooks::Model::PhysicalAddress.new
      address.line1   = hash_or_empty(order_address, 'address1')
      address.line2   = hash_or_empty(order_address, 'address2')
      address.line3   = hash_or_empty(order_address, 'address3')
      address.city    = hash_or_empty(order_address, 'city')
      address.country = hash_or_empty(order_address, 'country')
      address.country_sub_division_code = hash_or_empty(order_address, 'state')
      address.postal_code = hash_or_empty(order_address, 'zipcode')

      address
    end

    def self.hash_or_empty(hash, key)
      value = hash.nil? ? '' : hash[key]
    end
  end
end
