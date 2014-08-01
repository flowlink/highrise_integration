require 'rubygems'
require 'bundler'

Bundler.require(:default)

Dir["./lib/**/*.rb"].each { |f| require f }

require "./highrise_endpoint"
run HighriseEndpoint::Application
