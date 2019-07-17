require "pp"

module QBIntegration
  class Bill < Base

    def initialize(message = {}, config)
      super
      @bill = payload[:bill]
    end

    def create
      bill = bill_service.create
      code = 200
      summary = "Created Bill #{bill.doc_number}"

      [ code, summary, bill ]
    end
  end
end
