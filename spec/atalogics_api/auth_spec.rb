require 'spec_helper'

describe AtalogicsApi::Auth do
  before :each do
    real_configuration
  end

  describe 'initialize' do
    it "should set an access_token" do
      auth = AtalogicsApi::Auth.new "access_token"
      expect(auth.access_token).to eq("access_token")
    end

    it "should get the base_uri and change it when the config changes" do
      AtalogicsApi::Auth.set_base_uri
      expect(AtalogicsApi::Auth.base_uri).to eq("https://beta.atalogics.com/oauth/token")

      AtalogicsApi.configure do |config|
        config.sandbox_mode = true
      end
      AtalogicsApi::Auth.set_base_uri
      expect(AtalogicsApi::Auth.base_uri).to eq("https://sandbox.atalogics.com/oauth/token")

      allow(AtalogicsApi::Auth).to receive(:set_base_uri)
      AtalogicsApi::Auth.new "access_token"
      expect(AtalogicsApi::Auth).to have_received(:set_base_uri)
    end

    it "should NOT call for a new token, when a token is passed" do
      expect_any_instance_of(AtalogicsApi::Auth).not_to receive(:get_auth_token)
      auth = AtalogicsApi::Auth.new "access_token"
    end

    it "should call for a new token, when no access_token is set" do
      expect_any_instance_of(AtalogicsApi::Auth).to receive(:get_auth_token)
      auth = AtalogicsApi::Auth.new
    end

    it "should fetch a new token when initialize", :vcr do
      auth = AtalogicsApi::Auth.new
      expect(auth.code).to eq(200)
      expect(auth.access_token).to eq("83c4d60c815183220a05153d5029333f6b534f9c3117e663446109f6cde6d59e")
      expect(auth.token_type).to eq("bearer")
      expect(auth.expires_in).to eq(7200)
    end

    it "should raise an error, when the server returns 401", :vcr do
      AtalogicsApi.configure do |config|
        # invalid credentials
        config.client_secret = "invalid"
      end
      expect {
        AtalogicsApi::Auth.new
      }.to raise_error AtalogicsApi::Auth::AuthenticationFailed
    end

    it "should raise an error, when other things went wrong, and include the response body", :vcr do
      AtalogicsApi::Auth.base_uri("http://localhost:3000/oauth/token_wrong")
      expect {
        AtalogicsApi::Auth.new
      }.to raise_error AtalogicsApi::Auth::ApiError, /undefined local variable or method/
    end
  end
end
