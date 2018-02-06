module QBIntegration
  module Service
    class JournalEntry < Base
      attr_reader :payload, :journal_entry
      attr_reader :journal_line_service

      def initialize(config, payload)
        super("JournalEntry", config)

        @journal_entry = payload[:journal_entry]
        @journal_line_service = JournalLine.new config, payload
      end

      def find_by_id
        query = "SELECT * FROM JournalEntry WHERE DocNumber = '#{id}'"
        quickbooks.query(query).entries.first
      end

      def find_by_given_id(journal_id)
        query = "SELECT * FROM JournalEntry WHERE DocNumber = '#{journal_id}'"
        quickbooks.query(query).entries.first
      end

      def create
        journal = create_model
        build journal
        quickbooks.create journal
      end

      def update(journal)
        build journal
        quickbooks.update journal
      end

      def delete(journal)
        quickbooks.delete journal
      end

      private
        def id
          journal_entry[:number] || journal_entry[:id]
        end

        def build(journal)
          journal.doc_number = id
          journal.txn_date = journal_entry['journalDate']
          journal.line_items = journal_line_service.build_from_line_items
          journal
        end
    end
  end
end
