module QBIntegration
  module Processor
    class Address
      include Helper
      attr_reader :address

      def initialize(address)
        @address = address
      end

      def as_flowlink_hash
        {
          address1: address.line1,
          address2: address.line2,
          city: address.city,
          state: address.country_sub_division_code,
          country: address.country,
          zipcode: address.postal_code
        }
      end

    end
  end
end
