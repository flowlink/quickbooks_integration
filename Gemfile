source 'https://www.rubygems.org'

gem 'endpoint_base', :git=> 'git@github.com:spree/endpoint_base.git'
gem 'thin'
gem 'quickeebooks', :git => 'git://github.com/GeekOnCoffee/quickeebooks.git'
gem 'tzinfo'
gem 'capistrano'

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

