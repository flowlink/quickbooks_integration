require "spec_helper"

module QBIntegration
  describe Order do
    subject do
      described_class.new(message, config)
    end

    let(:message) do
      { order: Factories.add_order }
    end

    let(:config) { Factories.config }

    context "quotes on customer name" do
      it "handles it just fine" do
        VCR.use_cassette("sales_receipt/quotes_involved") do
          subject.create
        end
      end
    end
  end
end
