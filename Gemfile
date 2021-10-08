source 'https://www.rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'endpoint_base', :github => 'flowlink/endpoint_base'
gem 'honeybadger', '~> 4.0'
gem 'rest-client'

gem 'quickbooks-ruby', '~> 1.0.1'
gem 'tzinfo'
gem 'capistrano'
gem 'unicorn'
gem 'builder'

group :development do
  gem 'rake'
  gem 'pry-byebug'
  gem 'shotgun'
end

group :test do
  gem 'vcr'
  gem 'rspec', '~> 2.14'
  gem 'webmock'
  gem 'guard-rspec'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rack-test'
  gem 'simplecov'
end

group :production do
  gem 'foreman'
end
