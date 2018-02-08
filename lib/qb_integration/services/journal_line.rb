module QBIntegration
  module Service
    class JournalLine < Base
      attr_reader :line_items, :lines, :config, :journal_entry
      attr_reader :account_service, :customer_service, :class_service

      def initialize(config, payload)
        @config = config
        @model_name = "Line"
        @journal_entry = payload[:journal_entry] || {}
        @line_items = journal_entry[:line_items] || []

        @customer_service = Customer.new config, payload
        @account_service = Account.new config
        @class_service = Class.new config

        @lines = []
      end

      def build_from_line_items
        line_number = 0
        line_items.each do |line_item|
          line = create_model

          if line_item["credit"] != 0
            type = 'Credit'
            amount = line_item["credit"]
          else
            type = 'Debit'
            amount = line_item["debit"]
          end
          line.amount = amount
          line.description = line_item["account_description"]
          line.id = line_number

          line.journal_entry! do |journal_item|
            journal_item.account_id = line_item["account_number"]
            journal_item.posting_type = type

            # Assume the Customer/Account exists, because we don't have enough info to create a customer
            unless customer = customer_service.fetch_by_display_name(line_item['description'])
              raise RecordNotFound.new "Quickbooks Customer #{line_item[:description]} not found"
            end
            entity = Quickbooks::Model::Entity.new(type: 'Customer')
            entity.entity_id = customer["id"]
            journal_item.entity = entity
            account = account_service.find_by_name(line_item["account_description"])
            journal_item.account_id = account["id"]
            if line_item["class"]
              unless qb_class_id = class_service.find_by_name(line_item["class"]).id
                raise RecordNotFound.new "Quickbooks Class #{line_item[:class]} not found"
              end
              journal_item.class_id = qb_class_id
            end
            # TODO: Build out a Location Service to find and set a location on Journal Entry
          end
          line_number += 1
          lines.push line
        end
        lines
      end
    end
  end
end
