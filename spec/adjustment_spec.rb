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

  it "raises an exception when the adjustment does not has the 'originator_type' field" do
    adjustments = [
      {
        "id"=> 16,
        "amount"=> "5.0",
        "label"=> "Shipping",
        "mandatory"=> true,
        "eligible"=> true
      }
    ]
    expect { Adjustment.new(adjustments) }.to raise_error Exception, "Insuficient API Version. Needs to be bumped to at least 8240b6c0"
  end

  it "returns the adjustments without originator_type and amount < 0.0 as discount" do

    adjustments = [
      {
        "id" => 15,
        "amount" => "-5.0",
        "label" => "Special Test Discount",
        "mandatory" => nil,
        "eligible" => true,
        "originator_type" => nil,
        "adjustable_type" => "Spree::Order"
      }
    ]

    adjustment = Adjustment.new(adjustments)
    adjustment.discount.count.should eql 1
    adjustment.discount.first["amount"].should eql "-5.0"
    adjustment.discount.first["label"].should eql "Special Test Discount"
  end

  it "returns the adjustments without originator_type and amount > 0.0 as manual_charge" do

    adjustments = [
      {
        "id" => 15,
        "amount" => "5.0",
        "label" => "extra charge manual shipping and gift wrapping",
        "mandatory" => nil,
        "eligible" => true,
        "originator_type" => nil,
        "adjustable_type" => "Spree::Order"
      }
    ]

    adjustment = Adjustment.new(adjustments)
    adjustment.manual_charge.count.should eql 1
    adjustment.discount.count.should eql 0
    adjustment.manual_charge.first["amount"].should eql "5.0"
    adjustment.manual_charge.first["label"].should eql "extra charge manual shipping and gift wrapping"
  end

end