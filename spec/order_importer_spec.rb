require 'spec_helper'

describe OrderImporter do
  let(:order_id) { Augury::Orders.save(Factories.order('number' => "R123")) }
let(:store) { Factories.store('quickbooks' => { 'access_token' => 'qyprdUDbIJZOD8tgTynBSG0ViOLsS48KEl6cbMrHO9IrgXwT', 'access_secret' => 'TCT1y3gjPfZRuL6hg2nyx9xCJv4vxF3dXMjfKmap', 'realm' => '568190375' }) }

  let(:message) {{ 'order' => { 'actual' => Factories.order },
                                 'shipment_number' => 'H438105531460' }}
  
  subject { OrderImporter.new( message, {
                                  'access_token' => 'qyprdUDbIJZOD8tgTynBSG0ViOLsS48KEl6cbMrHO9IrgXwT',
                                  'access_secret' => 'TCT1y3gjPfZRuL6hg2nyx9xCJv4vxF3dXMjfKmap',
                                  'realm' => '568190375' }) }

  it 'imports the order to quickbooks' do
    VCR.use_cassette('quickbooks_order_import') do
      subject.should_receive(:create_item).exactly(3).times
      response = subject.consume
    end
  end

  it 'creates items' do
    VCR.use_cassette('quickbooks_order_import_create_items') do
      subject.send(:create_item, "Sales Tax",
                   "Shipping Charges", 0, 0, 0, "Other Charge")
    end
  end

  context "acceptability" do
    it "shouldn't be acceptable without config" do
      subject.quickbooks = {}
      subject.acceptable?.should be_false
    end

    it "shouldn't be acceptable without complete config" do
      subject.quickbooks = { 'realm' => '3' }
      subject.acceptable?.should be_false
    end

    it "should be acceptable with proper config" do
      subject.order['payment_state'] = 'paid'
      subject.acceptable?.should be_true
    end
  end

end
