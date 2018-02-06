module QBIntegration
  class JournalEntry < Base
    attr_reader :journal_entry_payload

    def initialize(message = {}, config)
      super

      @journal_entry_payload = @journal_entry = @payload[:journal_entry]
    end

    def add
      if journal_entry = journal_entry_service.find_by_id
        raise AlreadyPersistedJournalEntryException.new(
          "Journal Entry #{journal_entry[:id]} already has a journal entry with id: #{journal_entry.id}"
        )
      end
      journal_entry_service.create
      add_notification('create', @journal_entry)
      [200, @notification]
    end

    def update
    end

    def delete
      deleted = journal_entry_service.delete(@journal_entry)
    end

    private
    def account_id(account_name)
      account_service.find_by_name(account_name).id
    end

    def parent_ref
      @parent_ref ||= item_service.find_by_sku(@product[:sku]).id
    end

    def add_notification(operation, product)
      @notification = @notification.to_s + text[operation] % @journal_entry[:id] + " "
    end

    def text
      @text ||= {
        'create' => "Journal Entry %s imported to Quickbooks.",
        'update' => "Journal Entry %s updated on Quickbooks."
      }
    end

    def time_now
      Time.now.utc
    end
  end
end
