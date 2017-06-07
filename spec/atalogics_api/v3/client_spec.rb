require 'spec_helper'

describe AtalogicsApi::V3::Client, 'client base' do
  let(:test_method) { :offers }
  it_behaves_like 'client_base'
end

describe AtalogicsApi::V3::Client, '#offers', :vcr do
  before do
    real_configuration
    AtalogicsApi.configure do |config|
      config.cache_store = Redis.new
    end
  end

  let(:client) { described_class.new }
  let(:body) { { catch_address: 'Auerspergstr 44 Salzburg', drop_address: 'Getreidegasse 24 Salzburg' } }

  it 'returns offers' do
    response = client.offers body
    expect(response.code).to eq(200)
    expect(response.body["offers"]).not_to be_nil

    # check if http is NOT hit a second time
    expect(client.class).not_to receive(:post)

    cached_response = client.offers body
    expect(cached_response.code).to eq(response.code)
    expect(cached_response.body).to eq(response.body)

    cache_key = "V3_/offers_Auerspergstr 44 Salzburg_Getreidegasse 24 Salzburg"
    expect(AtalogicsApi.cache_store.keys).to eq([cache_key])
    expect(AtalogicsApi.cache_store.ttl(cache_key)).to eq(24*60*60)
  end

  describe '#offers!', :vcr do
    it 'wraps next_timeslots' do
      response = client.offers! body
      expect(response.code).to eq(200)
    end

    it 'raises an error when response.code != 200' do
      expect { client.offers!({}) }.to raise_error AtalogicsApi::Response::FailedError
    end
  end
end

describe AtalogicsApi::V3::Client, '#shipments', :vcr do
  before do
    real_configuration
  end

  let(:client) { described_class.new }

  it 'creates a shipment based on an offer key' do
    body = {
      offer_key: 'MjAxNy0wNi0wNysrNTUyNmJiMGM1NTYyNzUzMTJhMDYwMDAwKysyMDE3LTA2LTA3Kys1NTM4ZWM4MzU1NjI3NTJiOTAwMDAwMDA=',
      catch_address: { firstname: 'John', lastname: 'Doe', street: 'Auerspergstr', number: '44', postal_code: '5020', city: 'Salzburg', phone: '123' },
      drop_address:  { firstname: 'Jane', lastname: 'Doe', street: 'Auerspergstr', number: '12', postal_code: '5020', city: 'Salzburg', phone: '456' }
    }

    response = client.shipments body
    expect(response.code).to eq(201)
    expect(response.body["state"]).to eq("ordered")
  end
end
