require 'spec_helper'

describe OrderImporter do

      def config(message)
        conf = message[:payload]['parameters'] || []

        conf.inject({}) do |result, param|
          param.symbolize_keys!
          result[param[:name]] = param[:value]
          result
        end
      end

  let(:order_id) { Augury::Orders.save(Factories.order('number' => "R123")) }
  let(:store) { Factories.store('quickbooks' => { 'access_token' => 'qyprdUDbIJZOD8tgTynBSG0ViOLsS48KEl6cbMrHO9IrgXwT', 'access_secret' => 'TCT1y3gjPfZRuL6hg2nyx9xCJv4vxF3dXMjfKmap', 'realm' => '568190375' }) }

  let(:message) {
                  { 'order' => { 'actual' => Factories.order },
                                 'shipment_number' => 'H438105531460', 
                  :payload => {'parameters' => Factories.parameters }}
                }
  
  subject { OrderImporter.new( message, "",
                                 config(message) )  }

  it 'imports the order to quickbooks' do
    VCR.use_cassette('quickbooks_order_import') do
      subject.should_receive(:create_item).exactly(2).times
      response = subject.consume
    end
  end

  it 'creates items' do
    VCR.use_cassette('quickbooks_order_import_create_items') do
      subject.send(:create_item, "Sales Tax",
                   "Shipping Charges", 0, 0, 0, "Other Charge")
    end
  end
end
