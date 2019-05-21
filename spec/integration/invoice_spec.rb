require_relative 'spec_helper'

describe 'App' do
  let(:realm) { ENV['quickbooks_realm'] }
  let(:secret) { ENV['quickbooks_access_secret'] }
  let(:token) { ENV['quickbooks_access_token'] }
  let(:headers) {
    {
      "Content-Type": "application/json"
    }
  }

  include Rack::Test::Methods

  def app
    QuickbooksEndpoint
  end

  describe "#get_invoices", vcr: true do
    it "returns 206 and list of vendors" do
      post '/get_invoices', {
        "request_id": "25d4847a-a9ba-4b1f-9ab1-7faa861a4e67",
        "parameters": {
          "quickbooks_realm": realm,
          "quickbooks_access_token": token,
          "quickbooks_access_secret": secret,
          "quickbooks_since": "2017-03-11T18:48:56.001Z",
          "quickbooks_page_num": "1"
        }
      }.to_json, headers
      invoices = JSON.parse(last_response.body)['invoices']
      expect(last_response.status).to eq 200
      expect(invoices.size).to eq 12
    end
  end

end
