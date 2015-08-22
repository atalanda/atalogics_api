require 'spec_helper'

describe AtalogicsApi::Client do
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

  describe 'address_check', :vcr do
    it "should return success" do
      client = AtalogicsApi::Client.new
      response = client.address_check street: "Maxglaner Haupstr. 17", postal_code: 5020, city: "Salzburg"
      expect(response.parsed_response).to eq({"success" => true})
    end

    it "should return an error" do
      client = AtalogicsApi::Client.new
      response = client.address_check street: "Fakestreet 12", postal_code: 31415, city: "Faketown"
      expect(response.parsed_response).to eq({"error"=>["Adresse konnte nicht gefunden werden"]})
    end
  end

  describe "in_delivery_range?", :vcr do
    it "should return true" do
      client = AtalogicsApi::Client.new
      response = client.in_delivery_range? street: "Maxglaner Haupstr. 17", postal_code: 5020, city: "Salzburg"
      expect(response).to be(true)
    end

    it "should return false" do
      client = AtalogicsApi::Client.new
      response = client.in_delivery_range? street: "Fakestreet 12", postal_code: 31415, city: "Faketown"
      expect(response).to be(false)
    end
  end

  describe 'offers', :vcr do
    it "should return offers" do
      hash = {
        catch_address: {
          street: "Maxglaner Hauptstraße 12",
          postal_code: 5020,
          city: "Salzburg"
        },
        drop_address: {
          street: "Ignaz Harrer Straße 34",
          postal_code: 5020,
          city: "Salzburg"
        }
      }
      client = AtalogicsApi::Client.new
      response = client.offers hash
      arr = response.parsed_response
      expect(response.code).to eq(200)
      expect(arr.first['offer_id'].length).to be > 200 # just check if offer id is long enough, so that we get a real offer_id
      expect(arr.length).to eq(3)
    end
  end

  describe 'purchase_offer', :vcr do
    it "should purchase an offer" do
      # first get an offer
      hash = {
        catch_address: {
          street: "Maxglaner Hauptstraße 12",
          postal_code: 5020,
          city: "Salzburg"
        },
        drop_address: {
          street: "Ignaz Harrer Straße 34",
          postal_code: 5020,
          city: "Salzburg"
        }
      }
      client = AtalogicsApi::Client.new
      response = client.offers hash
      offer_id = response.parsed_response.first["offer_id"]

      # second: add information
      hash.merge!({
        offer_id: offer_id
      })
      hash[:catch_address].merge!({
        name: "Max Mustermann",
        phone: "123456789"
      })
      hash[:drop_address].merge!({
        name: "Maria Musterfrau",
        phone: "123456789"
      })
      response = client.purchase_offer hash
      shipment = response.parsed_response
      expect(response.code).to eq(201)
      expect(shipment["tracking_id"]).not_to be_nil
    end
  end

  describe '#next_delivery_time', :vcr do
    it 'returns the next delivery_times for an address' do
      client = AtalogicsApi::Client.new
      response = client.next_delivery_time address: "5020 Salzburg, Österreich"
      expect(response.parsed_response).to eq({"catch_time_window"=>{"from"=>"2015-08-24T08:00:00+02:00", "to"=>"2015-08-24T22:30:00+02:00"}, "drop_time_window"=>{"from"=>"2015-08-24T22:31:00+02:00", "to"=>"2015-08-24T23:59:00+02:00"}})
    end
  end
end
