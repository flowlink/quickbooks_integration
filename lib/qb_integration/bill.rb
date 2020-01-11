module QBIntegration
  class Bill < Base

    def initialize(message = {}, config)
      super
      @payload = payload
    end

    def create
      bill, po = bill_service.create
      code = 200
      summary = "Created Bill: #{bill[:doc_number]} with Purchase Order: #{po[:doc_number]}"

      [ code, summary, bill, po, bill_service.access_token ]
    end
  end
end
