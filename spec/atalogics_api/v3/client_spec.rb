# frozen_string_literal: true

require "spec_helper"

describe AtalogicsApi::V3::Client, "client base" do
  let(:test_method) { :offers }
  it_behaves_like "client_base"
end

describe AtalogicsApi::V3::Client, "#offers", :vcr do
  include_context "client_context"

  let(:body) { { catch_address: "Auerspergstr 44 Salzburg", drop_address: "Getreidegasse 24 Salzburg" } }

  it "returns offers" do
    Timecop.freeze "2017-06-07T12:00"

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
    expect(AtalogicsApi.cache_store.ttl(cache_key)).to eq(described_class::EXPIRES_IN_24_HOURS)
  end

  it "expires a key, when cached catch_window is older than Time.now" do
    # current time is one second after catch_window usable_till
    Timecop.freeze("2016-02-02T17:00:01")

    cache_key = "V3_/offers_bar"
    cached_body = { "offers" => [{ "catch_window" => { "usable_till" => "2016-02-02T17:00:00+01:00" } }] }
    AtalogicsApi.cache_store.set(cache_key, [200, cached_body].to_json)

    expect(client.class).to receive(:post).and_return(
      instance_double(HTTParty::Response, code: 200, parsed_response: { new: "response" })
    )

    client.offers("foo" => "bar")

    expect(AtalogicsApi.cache_store.get(cache_key)).to eq('[200,{"new":"response"}]')
  end

  describe "#offers!", :vcr do
    it "wraps next_timeslots" do
      response = client.offers! body
      expect(response.code).to eq(200)
    end

    it "raises an error when response.code != 200" do
      expect { client.offers!({}) }.to raise_error AtalogicsApi::Response::FailedError
    end
  end
end

describe AtalogicsApi::V3::Client, "#shipments", :vcr do
  include_context "client_context"
  include_context "non_cacheable_requests"

  it "creates a shipment based on an offer key" do
    body = {
      offer_key: "MjAxNy0wNi0wNysrNTUyNmJiMGM1NTYyNzUzMTJhMDYwMDAwKysyMDE3LTA2LTA3Kys1NTM4ZWM4MzU1NjI3NTJiOTAwMDAwMDA=",
      catch_address: { firstname: "John", lastname: "Doe", street: "Auerspergstr", number: "44", postal_code: "5020", city: "Salzburg", phone: "123" },
      drop_address:  { firstname: "Jane", lastname: "Doe", street: "Auerspergstr", number: "12", postal_code: "5020", city: "Salzburg", phone: "456" }
    }

    response = client.shipments body
    expect(response.code).to eq(201)
    expect(response.body["state"]).to eq("ordered")
    expect(AtalogicsApi.cache_store.keys).to be_empty
  end
end

describe AtalogicsApi::V3::Client, "#delivery_areas" do
  include_context "client_context"

  let(:city_key) { "SALZBURG" }
  let(:body) do
    {
      delivery_areas: ["some delivery areas"],
      key: "SALZBURG"
    }.to_json
  end

  before do
    stub_request(:post, "http://192.168.99.100:3100/oauth/token").to_return(status: 200, body: "")
    stub_request(:get, "http://192.168.99.100:3100/api/v3/cities/SALZBURG").
      to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })
  end

  it "returns delivery_areas either from cache or atalogics" do
    response = client.delivery_areas city_key
    expect(response.code).to eq(200)
    expect(response.body["delivery_areas"]).to_not be_nil
    expect(response.body["key"]).to eq city_key

    expect(client.class).not_to receive(:get)

    cached_response = client.delivery_areas city_key
    expect(cached_response.code).to eq(response.code)
    expect(cached_response.body).to eq(response.body)

    cache_key = "V3_/cities/#{city_key}"
    expect(AtalogicsApi.cache_store.keys).to eq([cache_key])
    expect(AtalogicsApi.cache_store.ttl(cache_key)).to eq(described_class::EXPIRES_IN_1_HOUR)
  end
end
