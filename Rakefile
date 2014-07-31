require 'rubygems'
require 'bundler'

Bundler.require(:default)

desc "Retrieve the environment of the application"
task :environment do
  require File.expand_path('highrise_endpoint', File.dirname(__FILE__)) # your Sinatra app
end

desc "Test the application"
task :test => :environment do
  exec 'RACK_ENV=test bundle exec rspec'
end

desc "Delete all VCR cassettes and saved request data"
task :clean => :environment do
  exec 'rm -rf ./spec/support/requests/*; rm -rf ./spec/vcr_cassettes/*'
end
