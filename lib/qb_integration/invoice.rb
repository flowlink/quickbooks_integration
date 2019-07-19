module QBIntegration
  class Invoice < Base
    attr_accessor :flowlink_invoice, :invoices, :new_page_number

    def initialize(message = {}, config)
      super
      @flowlink_invoice = payload[:invoice] ? payload[:invoice] : {}
    end

    def create
      if qb_invoice = invoice_service.find_by_invoice_number
        raise AlreadyPersistedOrderException.new("FlowLink Invoice #{flowlink_invoice[:id]} already exists - QuickBooks Invoice #{qb_invoice.id}")
      end

      invoice = invoice_service.create
      text = "Created QuickBooks Invoice #{invoice.doc_number}"
      [200, text]
    end

    def update
      qb_invoice = invoice_service.find_by_invoice_number

      if !qb_invoice.present? && config[:quickbooks_create_or_update].to_s == "1"
        invoice = invoice_service.create
        [200, "Created QuickBooks Invoice #{invoice.doc_number}"]
      elsif !qb_invoice.present?
        raise RecordNotFound.new "QuickBooks invoice not found for invoice #{flowlink_invoice[:number] || flowlink_invoice[:id]}"
      else
        invoice = invoice_service.update qb_invoice
        [200, "Updated QuickBooks invoice #{invoice.doc_number}"]
      end
    end

    def get
      @invoices, @new_page_number = invoice_service({ dependencies: false }).find_by_updated_at(page_number)
      summary = "Retrieved #{@invoices.count} invoices from QuickBooks Online"

      [summary, new_page_number, since, code]
    end

    def build_invoice(invoice)
      Processor::Invoice.new(invoice).as_flowlink_hash
    end

    private

    def page_number
      config.fetch("quickbooks_page_num").to_i || 1
    end

    def since
      new_page_number == 1 ? Time.now.utc.iso8601 : config.fetch("quickbooks_since")
    end

    def code
      new_page_number == 1 ? 200 : 206
    end
  end
end
