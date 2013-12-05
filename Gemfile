source 'https://www.rubygems.org'

gem 'endpoint_base', :github => 'spree/endpoint_base'
gem 'thin'
gem 'quickbooks-ruby', :github => 'ruckus/quickbooks-ruby'
gem 'tzinfo'
gem 'capistrano'

group :development do
  gem "rake"
  gem "pry"
end

group :test do
  gem 'vcr'
  gem 'rspec', '2.11.0'
  gem 'webmock'
  gem 'guard-rspec'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rack-test'
  gem 'debugger'
  gem 'simplecov'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end
