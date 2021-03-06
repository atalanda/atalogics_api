require 'spec_helper'

describe AtalogicsApi::Auth do
  before :each do
    real_configuration
  end

  describe 'initialize' do
    it "should set an access_token" do
      auth = AtalogicsApi::Auth.new "access_token", "bearer"
      expect(auth.access_token).to eq("access_token")
      expect(auth.token_type).to eq("bearer")
    end

    it "should raise an error, when access_token is set, but no token_type and vice versa" do
      expect {
        AtalogicsApi::Auth.new "access_token"
      }.to raise_error AtalogicsApi::Errors::AccessTokenAndTokenTypeMustBeSet

      expect {
        AtalogicsApi::Auth.new nil, "token_type"
      }.to raise_error AtalogicsApi::Errors::AccessTokenAndTokenTypeMustBeSet
    end

    it "should get the base_uri and change it when the config changes" do
      AtalogicsApi::Auth.set_base_uri
      expect(AtalogicsApi::Auth.base_uri).to eq("http://192.168.99.100:3100/oauth/token")

      AtalogicsApi.configure do |config|
        config.sandbox_mode = true
      end
      AtalogicsApi::Auth.set_base_uri
      expect(AtalogicsApi::Auth.base_uri).to eq("https://sandbox.atalogics.com/oauth/token")

      allow(AtalogicsApi::Auth).to receive(:set_base_uri)
      AtalogicsApi::Auth.new "access_token", "token_type"
      expect(AtalogicsApi::Auth).to have_received(:set_base_uri)
    end

    it "should NOT call for a new token, when a token is passed" do
      expect_any_instance_of(AtalogicsApi::Auth).not_to receive(:refresh_access_token)
      auth = AtalogicsApi::Auth.new "access_token", "token_type"
    end

    it "should call for a new token, when no access_token is set" do
      expect_any_instance_of(AtalogicsApi::Auth).to receive(:refresh_access_token)
      auth = AtalogicsApi::Auth.new
    end

    it "should fetch a new token when initialize", :vcr do
      auth = AtalogicsApi::Auth.new
      expect(auth.response.code).to eq(200)
      expect(auth.access_token.length).to be > 15
      expect(auth.token_type).to eq("bearer")
      expect(auth.expires_in).to be > 100 # just check if we have seconds left
    end

    it "should raise an error, when the server returns 401", :vcr do
      AtalogicsApi.configure do |config|
        # invalid credentials
        config.client_secret = "invalid"
      end
      expect {
        AtalogicsApi::Auth.new
      }.to raise_error AtalogicsApi::Errors::AuthenticationFailed
    end
  end
end
