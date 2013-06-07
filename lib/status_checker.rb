class StatusChecker < Client

  attr_accessor :id, :idDomain

  def after_initialize(message)
    @message = message
    @key = message.key
    @order = message.payload['order']['actual']
  end

  def consume
    verify_quickbooks_import
  end

  def verify_quickbooks_import
    response = receipt_service.fetch_by_id(id, idDomain)

    if response.nil?
      {
        'message_id' => @message_id,
        'events' => { 'code' => 400,
                      'error' => get_errors }
      }
    elsif response.synchronized == "true"
      { 'message_id' => @message_id }
    elsif response.synchronized == "false"
      {
        'message_id' => @message_id,
        'delay' => 6000,
        'update_url' => "/status/#{@idDomain}/#{@id}",
      }
    end

  end

  def get_errors
    begin
      return status_service.list().entries.select{|e| e.NgIdSet.NgObjectType == "SalesReceipt" and e.NgIdSet.NgId == @id}.collect{|e| e.MessageDesc}.join(", ")
    rescue 
      return "No Error Information Found"
    end
  end


end
