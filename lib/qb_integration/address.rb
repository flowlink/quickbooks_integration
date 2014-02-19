module QBIntegration
  module Address
    def self.build(order_address)
      address = Quickbooks::Model::PhysicalAddress.new
      address.line1   = order_address["address1"]
      address.line2   = order_address["address2"]
      address.city    = order_address["city"]
      address.country = order_address["country"]
      address.country_sub_division_code = order_address["state"]
      address.postal_code = order_address["zipcode"]

      address
    end
  end
end
