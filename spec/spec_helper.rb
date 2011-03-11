require 'rubygems'
require 'bundler/setup'
require 'simplecov'
SimpleCov.start
require 'github_metadata'

RSpec.configure do |config|
  # some (optional) config here
end

require 'vcr'

VCR.config do |c|
  c.allow_http_connections_when_no_cassette = true
  c.default_cassette_options = { :record => :new_episodes }
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.stub_with :webmock # or :fakeweb
end
