require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end
require 'rubygems'
require 'bundler'

Bundler.require(:default, :test)

ENV['ENDPOINT_KEY'] = 'x123'

require File.join(File.dirname(__FILE__), '..', 'quickbooks_endpoint.rb')
Dir["./spec/support/**/*.rb"].each {|f| require f}

Sinatra::Base.environment = 'test'

def app
  QuickbooksEndpoint
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end