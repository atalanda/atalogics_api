$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry-byebug'
require 'pry-alias'
require 'vcr'
require 'atalogics_api'
require 'timecop'
require 'redis'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:each) do
    AtalogicsApi.reset
    Redis.new(host: "redis").flushall
  end
end

Dir["./spec/shared_examples/**/*.rb"].each { |f| require f }

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
    config.client_id = "409747accefbde0b38c1c1a4be2b333786c251ce6043ee187e907697db43214c"
    config.client_secret = "f80c897f5160fdfef198cbaef011183c440b84ae103c0beb51807ba4b39acfc8"
    config.production_base_url = "http://192.168.99.100:3100"
  end

  # AtalogicsApi.configure do |config|
  #   config.client_id = "00aefc972aaad36e1fb232d0f6cebb39117ca8fc07e53f78647d8a1544dcfd0a"
  #   config.client_secret = "a3d677268a500e60a0b72ef9985a2460874fff9401a290da51ee383e24239e32"
  #   config.production_base_url = "https://sandbox.atalogics.com"
  # end
end

def allow_real_requests
  WebMock.allow_net_connect!
  test_configuration
end
