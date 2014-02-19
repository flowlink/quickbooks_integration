class CrossReference
  attr_accessor :xref

  def initialize
    require "pstore"
    @xref = PStore.new("log/xref.pstore")
    @xref.ultra_safe = true
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
