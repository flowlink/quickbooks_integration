module QBIntegration
  module Helper
    def lookup_value!(hash, key, ignore_case = false, default = nil)
      hash = Hash[hash.map{|k,v| [k.downcase,v]}] if ignore_case

      if default
        value = hash.fetch(key, default)
      else
        value = hash[key]
      end

      value || (raise LookupValueNotFoundException.new("Can't find the key '#{key}' in the provided mapping"))
    end

    def build_address(addr)
      return unless addr
      {
        id: addr["id"],
        address1: addr["line1"],
        address2: addr["line2"],
        address3: addr["line3"],
        address4: addr["line4"],
        address5: addr["line5"],
        city: addr["city"],
        country: addr["country"],
        state: addr["country_sub_division_code"],
        country_sub_division_code: addr["country_sub_division_code"],
        zipcode: addr["postal_code"],
        note: addr["note"],
        lat: addr["lat"],
        lon: addr["lon"]
      }
    end

    def build_ref(ref)
      return {} unless ref
      { name: ref["name"],id: ref["value"] }
    end

    def self.payment_method_names service
      fetch_names_hash service
    end

    def self.customer_names service
      fetch_names_hash service
    end

    def self.is_adjustment_tax?(adjustment_name)
      adjustment_name.downcase.match(/tax/)
    end

    def self.is_adjustment_discount?(adjustment_name)
      adjustment_name.downcase.match(/discount/)
    end

    def self.is_adjustment_shipping?(adjustment_name)
      adjustment_name.downcase.match(/shipping/)
    end

    def self.adjustment_product_from_qb(adjustment_name, params, payload_object)
      if is_adjustment_discount?(adjustment_name)
        payload_object['quickbooks_discount_item'] || params['quickbooks_discount_item']
      elsif is_adjustment_shipping?(adjustment_name)
        payload_object['quickbooks_shipping_item'] || params['quickbooks_shipping_item']
      elsif is_adjustment_tax?(adjustment_name)
        payload_object['quickbooks_tax_item'] || params['quickbooks_tax_item']
      else
        # Optional additional adjustments will be unmapped, i.e. the
        # adjustment_name is the sku
        adjustment_name
      end
    end

    private
    def self.fetch_names_hash service
      data = {}
      page = 1
      per_page = 20
      list = service.list([],page,per_page)
      while(list.count != 0) do
        list.entries.each do |entry|
          data[entry.id.value] = entry.name
        end
        page += 1
        list = service.list([],page,per_page)
      end
      data
    end
  end
end
