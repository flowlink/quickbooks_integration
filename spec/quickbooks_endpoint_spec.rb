require 'spec_helper'

describe QuickbooksEndpoint do
  def auth
    { 'HTTP_X_AUGURY_TOKEN' => 'x123', 'Content-Type' => 'application/json' }
  end

  def parameters
    [
      {:name => 'quickbooks.access_token', :value => "qyprdINz6x1Qccyyj7XjELX7qxFBE9CSTeNLmbPYb7oMoktC" },
      {:name => 'quickbooks.access_secret', :value => "wiCLZbYVDH94UgmJDdDWxpYFG2CAh30v0sOjOsDX" },
      {:name => 'quickbooks.realm', :value => "1014843225" },
      {:name => "quickbooks.deposit_to_account_name", :value => "Undeposited Funds"},
      {:name => "quickbooks.payment_method_name", :value => [
        {
          "master" => "MasterCard",
          "visa" => "Visa",
          "american_express" => "AmEx",
          "discover" => "Discover",
          "PayPal" => "PayPal"
        }]
      },
      {:name => "quickbooks.shipping_item", :value => "Shipping Charges"},
      {:name => "quickbooks.tax_item", :value => "State Sales Tax-NY"},
      {:name => "quickbooks.coupon_item", :value => "Coupons"},
      {:name => "quickbooks.discount_item", :value => "Discount"},
      {:name => "quickbooks.account_name", :value => "Inventory Asset"},
      {:name => "quickbooks.timezone", :value => "EST"}
    ]
  end

  describe "order sync" do
    let(:message) {
      {
        :message_id => "abc",
        :payload => {
          "order" => Factories.order,
          "original" => Factories.original,
          "parameters" => parameters
        }
      }.with_indifferent_access
    }

    context "new sales receipt" do
      shared_context "persist new sales receipt" do
        it "generates a json response with an info notification" do
          # change order number in case you want to persist a new order
          message[:payload][:order][:number] = "R4435534534"
          message[:payload][:order][:placed_on] = "2013-12-18 14:51:18 -0300"

          VCR.use_cassette("sales_receipt/sync_order_sales_receipt_post") do
            post '/order_persist', message.to_json, auth
            last_response.status.should eql 200

            response = JSON.parse(last_response.body)
            response["message_id"].should eql "abc"
            response["notifications"].first["subject"].should match "Created Quickbooks Sales Receipt"
          end
        end
      end

      context "with order:new" do
        before { message[:message] = "order:new" }
        include_context "persist new sales receipt"
      end

      context "with order:updated" do
        before { message[:message] = "order:updated" }
        include_context "persist new sales receipt"
      end
    end

    context "existing sales receipt with order:updated" do
      before { message[:message] = "order:updated" }

      it "updates sales receipt just fine" do
        VCR.use_cassette("sales_receipt/sync_updated_order_post") do
          post '/order_persist', message.to_json, auth
          last_response.status.should eql 200

          response = JSON.parse(last_response.body)
          response["message_id"].should eql "abc"
          response["notifications"].first["subject"].should match "Updated Quickbooks Sales Receipt"
        end
      end
    end

    context "order canceled" do
      before { message[:message] = "order:canceled" }

      it "generates a json response with an info notification" do
        # change order number in case you want to persist a credit memo
        message[:payload][:order][:number] = "R4435534534"

        VCR.use_cassette("credit_memo/sync_order_credit_memo_post") do
          post '/order_persist', message.to_json, auth
          last_response.status.should eql 200

          response = JSON.parse(last_response.body)
          response["message_id"].should eql "abc"
          response["notifications"].first["subject"].should match "Created Quickbooks Credit Memo"
        end
      end
    end
  end

  describe "return authorizations" do
    let(:message) do
      {
        message: "return_authorization:new",
        message_id: "abc",
        payload: {
          return_authorization: Factories.return_authorization,
          original: Factories.return_authorization,
          parameters: parameters
        }
      }.with_indifferent_access
    end

    it "generates a json response with an info notification" do
      VCR.use_cassette("credit_memo/sync_return_authorization_new") do
        post '/return_authorization_persist', message.to_json, auth
        last_response.status.should eql 200
        response = JSON.parse(last_response.body)
        response["notifications"].first["subject"].should match "Created Quickbooks Credit Memo"
      end
    end

    it "returns 500 if order return was not sync yet" do
      message[:payload][:return_authorization][:order][:number] = "imnotthereatall"

      VCR.use_cassette("credit_memo/return_authorization_non_sync_order") do
        post '/return_authorization_persist', message.to_json, auth
        last_response.status.should eql 500
        response = JSON.parse(last_response.body)
        response["notifications"].first["subject"].should match "Received return for order not sync"
      end
    end

    context "update" do
      before { message[:message] = "return_authorization:updated" }

      it "updates existing return just fine" do
        VCR.use_cassette("credit_memo/sync_return_authorization_updated") do
          post '/return_authorization_persist', message.to_json, auth
          last_response.status.should eql 200
          response = JSON.parse(last_response.body)
          response["notifications"].first["subject"].should match "Updated Quickbooks Credit Memo"
        end
      end
    end
  end
end
