require 'spec_helper'

describe Adjustment do

  let(:adjustments) { Factories.original["adjustments"] }
  let(:adjustment) { Adjustment.new(adjustments)}

  it "finds the eligable shipping adjustments" do
    adjustment.shipping.count.should eql 2
  end

  it "finds the tax adjustments" do
    adjustment.tax.count.should eql 1
  end
  #todo flesh out the coupon and discounts

end