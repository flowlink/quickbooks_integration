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
          "Journal Entry #{@journal_entry[:id]} already has a journal entry in QB with id: #{journal_entry.id}"
        )
      end
      journal_entry_service.create
      add_notification('create', @journal_entry)
      [200, @notification]
    end

    def update
      if journal = journal_entry_service.find_by_id
        journal_entry_service.update journal
        add_notification('update', @journal_entry)
        [200, @notification]
      else
        journal_entry_service.create
        add_notification('create', @journal_entry)
        [200, @notification]
      end

    end

    def delete
      unless journal = journal_entry_service.find_by_id
        raise RecordNotFound.new "Quickbooks Journal Entry #{journal_entry_payload[:id]} not found"
      end
      journal_entry_service.delete journal
      add_notification('delete', @journal_entry)
      [200, @notification]
    end

    private
    def account_id(account_name)
      account_service.find_by_name(account_name).id
    end

    def add_notification(operation, product)
      @notification = @notification.to_s + text[operation] % @journal_entry[:id] + ""
    end

    def text
      @text ||= {
        'create' => "Journal Entry %s added to Quickbooks.",
        'update' => "Journal Entry %s updated on Quickbooks.",
        'delete' => "Journal Entry %s deleted on Quickbooks."
      }
    end

    def time_now
      Time.now.utc
    end
  end
end
