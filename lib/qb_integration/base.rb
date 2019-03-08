module QBIntegration
  class Base
    include Helper

    attr_accessor :payload, :config

    def initialize(payload = {}, config)
      @config = config
      @payload = payload
    end

    def item_service
      @item_service ||= Service::Item.new(@config)
    end

    def account_service
      @account_service ||= Service::Account.new(@config)
    end

    def sales_receipt_service
      @receipt_service ||= Service::SalesReceipt.new(config, payload)
    end

    def journal_entry_service
      @journal_service ||= Service::JournalEntry.new(config, payload)
    end

    def credit_memo_service
      @credit_memo_service ||= Service::CreditMemo.new(config, payload)
    end

    def payment_method_service
      @payment_method_service ||= Service::PaymentMethod.new(config, payload)
    end

    def customer_service
      @customer_service ||= Service::Customer.new(config, payload)
    end

    def line_service
      @line_service ||= Service::Line.new(config, payload)
    end

    def class_service
      @class_service ||= Service::Class.new(config, payload)
    end

    def journal_line_service
      @journal_line_service ||= Service::JournalLine.new(config, payload)
    end

    def invoice_service
      @invoice_service ||= Service::Invoice.new(config, payload)
    end

    def invoice_line_service
      @invoice_line_service ||= Service::InvoiceLine.new(config, payload)
    end
  end

  class RecordNotFound < StandardError; end
  class InvalidPlatformException < StandardError; end
  class LookupValueNotFoundException < StandardError; end
  class UnsupportedException < StandardError; end
  class AlreadyPersistedOrderException < StandardError; end
  class AlreadyPersistedInvoiceException < StandardError; end
  class AlreadyPersistedJournalEntryException < StandardError; end
  class NoReceiptForOrderException < StandardError; end
  class NoSkuForOrderException < StandardError; end

  class MissingTimestampParam < StandardError
    def message
      "Parameter QuickBooks_poll_stock_timestamp should be a valid date. e.g 2014-04-13T18:48:56.001Z"
    end
  end
end
