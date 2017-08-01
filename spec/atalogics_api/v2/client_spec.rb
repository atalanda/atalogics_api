require 'spec_helper'

describe AtalogicsApi::V2::Client, 'client base' do
  include_context 'client_context'
  let(:test_method) { :address_check }
  it_behaves_like 'client_base'
end

describe AtalogicsApi::V2::Client, 'endpoints' do
  include_context 'client_context'

  describe 'address_check', :vcr do
    it "returns success" do
      response = client.address_check street: "Maxglaner Haupstr.", number: "17", postal_code: 5020, city: "Salzburg"
      expect(response.body).to eq({"success" => true, "existent" => true})
    end

    it "returns an error" do
      response = client.address_check street: "Fakestreet", number: "12", postal_code: 31415, city: "Faketown"
      expect(response.body).to eq({"success" => false, "existent" => false, "error"=>["Adresse konnte nicht gefunden werden"]})
    end
  end

  describe 'multi_address_check', :vcr do
    it 'checks multiple addresses' do
      addresses = {
        addresses: [
          {lat: 47.8065258, lng: 13.0474424},
          {street: "Radetzkystrasse", number: "7", postal_code: 5020, city: "Salzburg"}
        ]
      }
      response = client.multi_address_check addresses
      expect(response.body).to eq({"success" => true, "same_area" => true, "existent" => true})
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
      expect(arr.length).to be > 2
    end
  end

  describe 'purchase_offer', :vcr do
    include_context 'non_cacheable_requests'

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

  describe '#next_timeslots', :vcr do
    shared_examples 'returns_next_timeslots' do
      it 'returns next delivery times' do
        response = client.next_timeslots body
        pair = response.body.first
        expect(pair["catch_time_window"]["from"]).not_to be_empty
        expect(pair["catch_time_window"]["to"]).not_to be_empty
        expect(pair["catch_time_window"]["date"]).not_to be_empty
        expect(pair["catch_time_window"]["timeslot_id"]).not_to be_empty

        expect(pair["drop_time_window"]["from"]).not_to be_empty
        expect(pair["drop_time_window"]["to"]).not_to be_empty
        expect(pair["drop_time_window"]["date"]).not_to be_empty
        expect(pair["drop_time_window"]["timeslot_id"]).not_to be_empty
      end
    end

    context 'address' do
      let(:body) { { address: "5020 Salzburg, Österreich" } }
      it_behaves_like 'returns_next_timeslots'
    end

    context 'position' do
      let(:body) { { position: {lat: 47.8027886, lng: 12.9862187} } }
      it_behaves_like 'returns_next_timeslots'
    end
  end

  describe '#next_timeslots!', :vcr do
    it 'wraps next_timeslots' do
      response = client.next_timeslots!({ address: "5020 Salzburg, Österreich" })
      expect(response.code).to eq(200)
    end

    it 'raises an error when response.code != 200' do
      expect {
        client.next_timeslots!({ address: "Foobar" })
      }.to raise_error(AtalogicsApi::Response::FailedError, '#<AtalogicsApi::Response, code: 404, body: {"error"=>"no_city_found"}>')
    end
  end
end

describe AtalogicsApi::V2::Client, 'cached requests' do
  include_context 'client_context'

  shared_examples 'cached_response' do
    it 'caches a response' do
      Timecop.freeze("2016-02-02T12:00:01") # VCR cassetts are recorded at 2016-02-02

      # first store it in the cache
      response = client.send(endpoint, body)
      expect(response.code).to eq(200)

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
    let(:cache_key) { "V2_/addresses/single/check_Radetzkystrasse_7_5020_Salzburg__" }

    it_behaves_like 'cached_response'
  end

  describe 'address_check with lat/lng', :vcr do
    let(:endpoint) { :address_check }
    let(:body) { {lat: 47.8065258, lng: 13.0474424} }
    let(:cache_key) { "V2_/addresses/single/check_____47.8065258_13.0474424" }

    it_behaves_like 'cached_response'
  end

  describe 'multi_address_check', :vcr do
    let(:endpoint) { :multi_address_check }
    let(:body) {{
      city_key: "SALZBURG",
      addresses: [
        {lat: 47.8065258, lng: 13.0474424},
        {street: "Radetzkystrasse", number: "7", postal_code: 5020, city: "Salzburg"}
      ]
    }}
    let(:cache_key) { "V2_/addresses/multi/check_SALZBURG_____47.8065258_13.0474424_Radetzkystrasse_7_5020_Salzburg__" }

    it_behaves_like 'cached_response'
  end

  describe 'next_timeslots: address', :vcr do
    let(:endpoint) { :next_timeslots }
    let(:body) { {address: "Salzburg"} }
    let(:cache_key) { "V2_/next_timeslots_Salzburg" }

    it_behaves_like 'cached_response'
  end

  describe 'next_timeslots: from', :vcr do
    let(:endpoint) { :next_timeslots }
    let(:body) { {address: "Salzburg", from: "2016-12-02T12:00:00"} }
    let(:cache_key) { "V2_/next_timeslots_Salzburg_from_2016-12-02T12:00:00" }

    it_behaves_like 'cached_response'
  end

  describe 'next_timeslots: from, to', :vcr do
    let(:endpoint) { :next_timeslots }
    let(:body) { {address: "Salzburg", from: '2017-06-07T12:00:00', to: "2017-06-08T12:00:00"} }
    let(:cache_key) { "V2_/next_timeslots_Salzburg_from_2017-06-07T12:00:00_to_2017-06-08T12:00:00" }

    it_behaves_like 'cached_response'
  end

  describe 'next_timeslots: position', :vcr do
    let(:endpoint) { :next_timeslots }
    let(:body) { { position: {lat: 47.8027886, lng: 12.9862187} } }
    let(:cache_key) { "V2_/next_timeslots_47.8027886_12.9862187" }

    it_behaves_like 'cached_response'

    it 'expires a key, when cached catch_time_window is older than Time.now' do
      # current time is one second after catch time to
      Timecop.freeze("2016-02-02T17:00:01")

      cached_body = [{"catch_time_window" => {"bookable_till" => "2016-02-02T17:00:00+01:00"}}]
      AtalogicsApi.cache_store.set(cache_key, [200, cached_body].to_json)

      expect(client.class).to receive(:post).and_return(double("httparty_response", code: 200, parsed_response: {new: "response"}))

      client.next_timeslots(body)

      expect(AtalogicsApi.cache_store.get(cache_key)).to eq('[200,{"new":"response"}]')
    end
  end

  it 'doesnt cache a failing response', :vcr do
    # this returns a 404 status, timeslots not found
    response = client.next_timeslots(address: "Fake Town")
    expect(AtalogicsApi.cache_store.keys.count).to eq(0)
  end

  it 'skips storing a hash key for other endpoints which dont support caching (e.g. #offers)', :vcr do
    response = client.offers({})
    expect(AtalogicsApi.cache_store.keys('*')).to eq([])
  end
end
