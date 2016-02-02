require 'spec_helper'

describe AtalogicsApi::Client, 'configure auth' do
  before :each do
    real_configuration
  end

  describe 'initialize' do
    it "should pass an access_token and token_type to the auth class" do
      client = AtalogicsApi::Client.new access_token: "some_access_token", token_type: "token_type"
      expect(client.auth.access_token).to eq("some_access_token")
      expect(client.auth.token_type).to eq("token_type")
    end
  end

  it "should refresh the access_token", :vcr do
    client = AtalogicsApi::Client.new
    old_access_token = client.access_token
    client.refresh_access_token
    expect(client.access_token).not_to eq(old_access_token)
  end

  describe 'auto_refresh_access_token', :vcr do
    it "should auto refresh the access_token, when option is set" do
      client = AtalogicsApi::Client.new access_token: "EXPIRED_TOKEN", token_type: "bearer", auto_refresh_access_token: true
      client.address_check({})
      expect(client.access_token.length).to be > 20
    end

    it "should raise an authentication error, after unsuccessful refresh of the token" do
      AtalogicsApi.configure do |config|
        config.client_id = 'wrong_client_id'
        config.client_secret = 'wrong_client_secret'
      end
      client = AtalogicsApi::Client.new access_token: "EXPIRED_TOKEN", token_type: "bearer", auto_refresh_access_token: true
      expect {
        client.address_check({})
      }.to raise_error AtalogicsApi::Errors::AuthenticationFailed
    end
  end

  describe 'on_access_token_change', :vcr do
    it "should call the given block, when a token has changed" do
      client = AtalogicsApi::Client.new access_token: "EXPIRED_TOKEN", token_type: "bearer"
      block_called = false
      client.on_access_token_change do |access_token, token_type, expires_in|
        expect(access_token.length).to be > 20
        expect(token_type).to eq("bearer")
        expect(expires_in).to be > 1000
        block_called = true
      end
      client.refresh_access_token
      expect(block_called).to be(true)
    end
  end
end

describe AtalogicsApi::Client, 'endpoints' do
  before :each do
    real_configuration
  end

  let(:client) { AtalogicsApi::Client.new }

  describe 'address_check', :vcr do
    it "returns success" do
      response = client.address_check street: "Maxglaner Haupstr.", number: "17", postal_code: 5020, city: "Salzburg"
      expect(response.body).to eq({"success" => true})
    end

    it "returns an error" do
      response = client.address_check street: "Fakestreet", number: "12", postal_code: 31415, city: "Faketown"
      expect(response.body).to eq({"success" => false, "error"=>["Adresse konnte nicht gefunden werden"]})
    end
  end

  describe "in_delivery_range?", :vcr do
    it "returns true" do
      response = client.in_delivery_range? street: "Maxglaner Haupstr.", number: "17", postal_code: 5020, city: "Salzburg"
      expect(response).to be(true)
    end

    it "returns false" do
      response = client.in_delivery_range? street: "Fakestreet", number: "12", postal_code: 31415, city: "Faketown"
      expect(response).to be(false)
    end
  end

  describe 'offers', :vcr do
    it "returns offers" do
      hash = {
        catch_address: {
          street: "Maxglaner Hauptstraße",
          number: "12",
          postal_code: 5020,
          city: "Salzburg"
        },
        drop_address: {
          street: "Ignaz Harrer Straße",
          number: "34",
          postal_code: 5020,
          city: "Salzburg"
        }
      }
      response = client.offers hash
      arr = response.body
      expect(response.code).to eq(200)
      expect(arr.first['offer_id'].length).to be > 200 # just check if offer id is long enough, so that we get a real offer_id
      expect(arr.length).to be > 3
    end
  end

  describe 'purchase_offer', :vcr do
    it "should purchase an offer" do
      # first get an offer
      hash = {
        catch_address: {
          street: "Maxglaner Hauptstraße",
          number: "12",
          postal_code: 5020,
          city: "Salzburg"
        },
        drop_address: {
          street: "Ignaz Harrer Straße",
          number: "34",
          postal_code: 5020,
          city: "Salzburg"
        }
      }
      response = client.offers hash
      offer_id = response.body.first["offer_id"]

      # second: add information
      hash.merge!({
        offer_id: offer_id
      })
      hash[:catch_address].merge!({
        firstname: "Max",
        lastname: "Mustermann",
        phone: "123456789"
      })
      hash[:drop_address].merge!({
        firstname: "Maria",
        lastname: "Musterfrau",
        phone: "123456789"
      })
      response = client.purchase_offer hash
      shipment = response.body
      expect(response.code).to eq(201)
      expect(shipment["tracking_id"]).not_to be_nil
    end
  end

  describe '#next_delivery_time', :vcr do
    shared_examples 'returns_next_delivery_times' do
      it 'returns next delivery times' do
        response = client.next_delivery_time body
        expect(response.body).to eq({
          "catch_time_window" => {"from"=>"2016-02-02T08:00:00+01:00", "to"=>"2016-02-02T22:30:00+01:00"},
          "drop_time_window" => {"from"=>"2016-02-02T22:31:00+01:00", "to"=>"2016-02-02T23:59:00+01:00"}
        })
      end
    end

    context 'address' do
      let(:body) { { address: "5020 Salzburg, Österreich" } }
      it_behaves_like 'returns_next_delivery_times'
    end

    context 'position' do
      let(:body) { { position: {lat: 47.8027886, lng: 12.9862187} } }
      it_behaves_like 'returns_next_delivery_times'
    end
  end
end

describe AtalogicsApi::Client, 'cached requests' do
  before :each do
    real_configuration
    AtalogicsApi.configure do |config|
      config.cache_store = Redis.new
    end
  end

  let(:client) { AtalogicsApi::Client.new }
  let(:redis) { Redis.new }

  shared_examples 'cached_response' do
    it 'caches a response' do
      # first store it in the cache
      response = client.send(endpoint, body)

      # check if http is NOT hit a second time
      expect(client.class).not_to receive(:post)
      cached_response = client.send(endpoint, body)
      expect(cached_response.code).not_to be_nil
      expect(cached_response.body).not_to be_nil
      expect(cached_response.code).to eq(response.code)
      expect(cached_response.body).to eq(response.body)

      expect(AtalogicsApi.cache_store.keys).to eq([cache_key])
      expect(AtalogicsApi.cache_store.ttl(cache_key)).to eq(24*60*60)
    end
  end

  describe 'address_check', :vcr do
    let(:endpoint) { :address_check }
    let(:body) { {street: "Radetzkystrasse", number: "7", postal_code: 5020, city: "Salzburg"} }
    let(:cache_key) { "/addresses/single/check_Radetzkystrasse_7_5020_Salzburg" }

    it_behaves_like 'cached_response'
  end

  describe 'next_delivery_time: address', :vcr do
    let(:endpoint) { :next_delivery_time }
    let(:body) { {address: "Salzburg"} }
    let(:cache_key) { "/next_delivery_time_Salzburg" }

    it_behaves_like 'cached_response'
  end

  describe 'next_delivery_time: position', :vcr do
    let(:endpoint) { :next_delivery_time }
    let(:body) { { position: {lat: 47.8027886, lng: 12.9862187} } }
    let(:cache_key) { "/next_delivery_time_47.8027886_12.9862187" }

    it_behaves_like 'cached_response'

    it 'expires a key, when cached catch_time_window is older than Time.now' do
      # current time is one second after catch time to
      Timecop.freeze("2016-02-02T17:00:01")

      cached_body = {"catch_time_window"=>{"to"=>"2016-02-02T17:00:00+01:00"}}
      AtalogicsApi.cache_store.set(cache_key, [200, cached_body].to_json)

      expect(client.class).to receive(:post).and_return(double("httparty_response", code: 200, parsed_response: {new: "response"}))

      client.next_delivery_time(body)

      expect(AtalogicsApi.cache_store.get(cache_key)).to eq('[200,{"new":"response"}]')
    end
  end

  it 'skips storing a hash key for other endpoints which dont support caching (e.g. #offers)', :vcr do
    response = client.offers({})
    expect(AtalogicsApi.cache_store.keys('*')).to eq([])
  end
end
