source "https://www.rubygems.org"

gem "sinatra"
gem "tilt", "~> 1.4.1"
gem "tilt-jbuilder", require: "sinatra/jbuilder"

gem "endpoint_base", github: "spree/endpoint_base"
gem 'capistrano'

gem 'honeybadger'

gem "highrise"
gem 'shotgun'

group :test do
  gem "pry"
  gem "faker"
  gem 'vcr'
  gem 'rspec'
  gem 'rack-test'
  gem 'webmock'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end
