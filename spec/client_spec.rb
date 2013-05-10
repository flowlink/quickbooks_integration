require 'spec_helper'

describe Client do
  let(:message) {{ 'order' => { 'actual' => Factories.order },
                               'shipment_number' => 'H438105531460' }}
  subject { Client.new(message, {
                                  'access_token' => 'qyprdUDbIJZOD8tgTynBSG0ViOLsS48KEl6cbMrHO9IrgXwT',
                                  'access_secret' => 'TCT1y3gjPfZRuL6hg2nyx9xCJv4vxF3dXMjfKmap',
                                  'realm' => '568190375' }) }

  it "shouldn't be acceptable without config" do
    quickbooks = OrderUpdater.new( message, {})
    quickbooks.acceptable?.should be_false
  end

  it "shouldn't be acceptable without complete config" do
    quickbooks = OrderUpdater.new( message, {'realm' => 3})
    quickbooks.acceptable?.should be_false
  end

  it "should be acceptable with proper config" do
    subject.acceptable?.should be_true
  end
end
