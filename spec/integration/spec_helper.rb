require 'rack/test'
require 'rubygems'
require 'bundler'
require 'vcr'
Bundler.require(:default, :test)
require File.join(File.dirname(__FILE__), '..', '../lib/qb_integration.rb')
require File.join(File.dirname(__FILE__), '..', '../quickbooks_endpoint')

VCR.configure do |c|
  c.cassette_library_dir = "spec/vcr"
  c.hook_into :webmock
  c.filter_sensitive_data('<REALM>') { ENV.fetch('quickbooks_realm') }
  c.filter_sensitive_data('<TOKEN>') { ENV.fetch('quickbooks_access_token') }
  c.filter_sensitive_data('<SECRET>') { ENV.fetch('quickbooks_access_secret') }
  c.configure_rspec_metadata!
end
