require 'spec_helper'

module QBIntegration
  module Service
    describe CreditMemo do
      let(:config) { Factories.config }

      subject { CreditMemo.new(config, payload) }

      context "order message" do
        let(:payload) do
          {
            "order" => Factories.new_credit_memo[:order]
          }.with_indifferent_access
        end

        it "creates from sales receipt" do
          VCR.use_cassette("credit_memo/create_from_receipt", match_requests_on: [:body, :method]) do
            sales_receipt = Service::SalesReceipt.new(config, payload).find_by_order_number
            credit_memo = subject.create_from_receipt sales_receipt
            expect(credit_memo.doc_number).to eq sales_receipt.doc_number
          end
        end
      end

      context "return authorization message" do
        let(:payload) do
          {
            return: Factories.return_authorization,
            order: { id: Factories.return_authorization[:order_id] }
          }.with_indifferent_access
        end

        it "creates credit memo given payload and sales receipt" do
          VCR.use_cassette("credit_memo/create_from_return", match_requests_on: [:method, :body]) do
            sales_receipt = Service::SalesReceipt.new(config, payload, dependencies: false).find_by_order_number
            expect(subject.create_from_return Factories.return_authorization, sales_receipt).to be
          end
        end

        it "updates credit memo given payload and sales receipt" do
          VCR.use_cassette("credit_memo/updates_from_return", match_requests_on: [:method, :body]) do
            sales_receipt = Service::SalesReceipt.new(config, payload, dependencies: false).find_by_order_number

            credit_memo = subject.find_by_number Factories.return_authorization["number"]
            sales_receipt.email = "creditmemo_updated@quickbooks.com"
            credit_memo_updated = subject.update credit_memo, Factories.return_authorization, sales_receipt
            expect(credit_memo_updated.bill_email.address).to eq "creditmemo_updated@quickbooks.com"
          end
        end
      end
    end
  end
end
