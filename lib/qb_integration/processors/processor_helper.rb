# module QBIntegration
#   module Processor
#     module ProcessorHelper
#       def build_address(addr)
#         return unless addr
#         {
#           id: addr["id"],
#           address1: addr["line1"],
#           address2: addr["line2"],
#           address3: addr["line3"],
#           address4: addr["line4"],
#           address5: addr["line5"],
#           city: addr["city"],
#           country: addr["country"],
#           state: addr["country_sub_division_code"],
#           country_sub_division_code: addr["country_sub_division_code"],
#           zipcode: addr["postal_code"],
#           note: addr["note"],
#           lat: addr["lat"],
#           lon: addr["lon"]
#         }
#       end

#       def build_ref(ref)
#         return {} unless ref
#         { name: ref["name"],id: ref["value"] }
#       end
#     end
#   end
# end