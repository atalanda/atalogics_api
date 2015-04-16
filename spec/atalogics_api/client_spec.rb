require 'spec_helper'

describe AtalogicsApi::Client do
  before :each do
    real_configuration
  end

  describe 'initialize' do
    it "should pass an access_token to the auth class" do

    end
  end

  describe 'address_check', :vcr do
    it "should return success" do
      client = AtalogicsApi::Client.new
      response = client.address_check street: "Maxglaner Haupstr. 17", postal_code: 5020, city: "Salzburg"
      expect(response.to_hash).to eq({"success" => true})
    end

    it "should return an error" do
      client = AtalogicsApi::Client.new
      response = client.address_check street: "Fakestreet 12", postal_code: 31415, city: "Faketown"
      expect(response.to_hash).to eq({"error"=>["Adresse konnte nicht gefunden werden"]})
    end
  end
end
