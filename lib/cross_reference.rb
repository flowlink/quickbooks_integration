class CrossReference
  attr_accessor :xref

  def initialize
    require "pstore"
    @xref = PStore.new("data/xref.pstore")
    @xref.ultra_safe = true
  end

  def add_customer(spree_user_id, quickbooks_id)
    xref.transaction do
      xref[spree_user_id] = {:quickbooks_id => quickbooks_id}
    end
  end

  def lookup_customer(spree_user_id)
    xref.transaction do
      xref[spree_user_id]
    end
  end

  def add(order_number, id, id_domain )
    xref.transaction do
      xref[order_number] = {:id => id, :id_domain => id_domain}
    end
  end

  def lookup(order_number)
    xref.transaction do
      xref[order_number]
    end
  end

end