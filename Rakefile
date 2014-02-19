require "rubygems"
require "bundler"
Bundler.setup

require "rake"

desc "Open an irb (or pry) session preloaded with the client"
task :console do
  begin
    require 'pry'
    sh %{pry -I lib/quickbooks -r client.rb}
  rescue LoadError => _
    sh 'irb -rubygems -I lib -r quickbooks_endpoint.rb'
  end
end
