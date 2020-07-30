module QBIntegration
  class CreditMemo < Base
    attr_accessor :flowlink_credit_memo

    def initialize(message = {}, config)
      super
      @flowlink_credit_memo = payload[:credit_memo] ? payload[:credit_memo] : {}
    end

    def create
      if credit_memo = credit_memo_service.find_by_number(@flowlink_credit_memo[:id])
        raise AlreadyPersistedOrderException.new("FlowLink Credit Memo #{flowlink_credit_memo[:id]} already exists - QuickBooks Credit Memo #{credit_memo.id}")
      end

      credit_memo = credit_memo_service.create
      flowlink_credit_memo[:qbo_id] = credit_memo.id
      text = "Created QuickBooks Credit Memo: #{credit_memo.doc_number}"
      [200, text, flowlink_credit_memo]
    end

    def update
      credit_memo = credit_memo_service.find_by_number(@flowlink_credit_memo[:id])

      if !credit_memo.present? && config[:quickbooks_create_or_update].to_s == "1"
        credit_memo = credit_memo_service.create
        text = "Created QuickBooks Credit Memo: #{credit_memo.doc_number}"
        flowlink_credit_memo[:qbo_id] = credit_memo.id
        [200, text, flowlink_credit_memo]
      elsif !credit_memo.present?
        raise RecordNotFound.new "QuickBooks credit memo not found for doc_number #{flowlink_credit_memo[:number] || flowlink_credit_memo[:id]}"
      else
        credit_memo = credit_memo_service.update_memo(credit_memo)
        text = "Update QuickBooks Credit Memo: #{credit_memo.doc_number}"
        flowlink_credit_memo[:qbo_id] = credit_memo.id
        [200, text, flowlink_credit_memo]
      end
    end

  end
end
