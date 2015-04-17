$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry-byebug'
require 'pry-alias'
require 'vcr'
require 'atalogics_api'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:each) do
    AtalogicsApi.reset
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.default_cassette_options = { record: :once, match_requests_on: [:method, :uri, :body]}
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_localhost = false
  c.allow_http_connections_when_no_cassette = false
end

def dummy_configuration
  AtalogicsApi.configure do |config|
    config.client_id = "some_client_id"
    config.client_secret = "some_client_secret"
  end
end

def real_configuration
  AtalogicsApi.configure do |config|
    config.client_id = "bc8287cb2899d86ad2427ee632ed002ab9576eddf68ef028ab9f0f14c5a32e53"
    config.client_secret = "2457530252f197bf7a4ec07555367e52e02e5b0f6526be79bf46d980dd643de5"
    config.production_base_url = "http://localhost:3000"
  end
end

def allow_real_requests
  WebMock.allow_net_connect!
  test_configuration
end
