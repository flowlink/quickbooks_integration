class Adjustment


  def initialize(adjustments={})
    @adjustments = adjustments.select{|a| a["eligible"] == true}
    raise "Insuficient API Version. Needs to be bumped to at least 8240b6c0" if (@adjustments.count > 0 && !@adjustments.first.has_key?("originator_type"))
  end

  def shipping
    @adjustments.select{|a| a["originator_type"] == 'Spree::ShippingMethod'}
  end

  def tax
    @adjustments.select{|a| a["originator_type"] == 'Spree::TaxRate' && a["adjustable_type"] == 'Spree::Order'}
  end

  def coupon 
    @adjustments.select{|a| a["originator_type"] == 'Spree::PromotionAction'}
  end

  def discount 
    @adjustments.select{|a| a["originator_type"] == nil}
  end

end
