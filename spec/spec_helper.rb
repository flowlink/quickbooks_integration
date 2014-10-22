require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end
require 'rubygems'
require 'bundler'
require "pstore"

require 'dotenv'
Dotenv.load

require 'spree/testing_support/controllers'

Bundler.require(:default, :test)

ENV['ENDPOINT_KEY'] = 'x123'

require File.join(File.dirname(__FILE__), '..', 'lib/qb_integration.rb')
require File.join(File.dirname(__FILE__), '..', 'quickbooks_endpoint')
Dir["./spec/support/**/*.rb"].each {|f| require f}

Sinatra::Base.environment = 'test'

def app
  QuickbooksEndpoint
end

VCR.configure do |c|
  # c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock

  c.filter_sensitive_data('oauth_consumer_key') { |_| ENV['QB_CONSUMER_KEY'] }
  c.filter_sensitive_data('oauth_token')        { |_| ENV['QB_CONSUMER_SECRET'].gsub('@','%40') }
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spree::TestingSupport::Controllers
end
