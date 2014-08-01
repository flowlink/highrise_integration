require "rubygems"
require "bundler"

Bundler.require(:default, :test)

require File.join(File.dirname(__FILE__), '..', "highrise_endpoint")

Dir["./spec/support/**/*.rb"].each { |f| require f }
Dir["./lib/**/*.rb"].each { |f| require f }

require "spree/testing_support/controllers"

Sinatra::Base.environment = 'test'

ENV["HIGHRISE_SITE_URL"] ||= "http://www.example.com"
ENV["HIGHRISE_API_TOKEN"] ||= "thisIsAFakeKey123"

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.default_cassette_options = { match_requests_on: [:method, :path] }
  config.hook_into :webmock

  config.filter_sensitive_data("HIGHRISE_SITE_HOST") {
    URI(ENV["HIGHRISE_SITE_URL"].blank? ? "http://www.example.com" : ENV["HIGHRISE_SITE_URL"]).host
  }

  config.filter_sensitive_data("HIGHRISE_API_TOKEN") {
    ENV["HIGHRISE_API_TOKEN"].blank? ? "thisIsAFakeKey123" : ENV["HIGHRISE_API_TOKEN"]
  }
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spree::TestingSupport::Controllers
end

# This is used to override the generated request parameters, so that they are real values.
def set_highrise_parameters(request)
  request[:parameters]["highrise_api_token"] = ENV["HIGHRISE_API_TOKEN"]
  request[:parameters]["highrise_site_url"] = ENV["HIGHRISE_SITE_URL"]
end

def line_items_to_string(line_items)
  line_items.map{ |line_item|
    "##{line_item[:product_id]} - \"#{line_item[:name]}\" | #{line_item[:quantity]} @ #{line_item[:price]/100.00}/each"
  }.join("\n")
end
