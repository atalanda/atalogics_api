shared_context 'client_context' do
  before do
    real_configuration
    AtalogicsApi.configure do |config|
      config.cache_store = Redis.new(host: "redis")
    end
  end

  let(:client) { described_class.new }
  let(:redis) { Redis.new(host: "redis") }
end

shared_context 'non_cacheable_requests' do
  after do
    expect(AtalogicsApi.cache_store.keys).to be_empty
  end
end
