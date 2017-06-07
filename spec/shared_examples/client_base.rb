shared_examples 'client_base' do
  before :each do
    real_configuration
  end

  describe 'initialize' do
    it "should pass an access_token and token_type to the auth class" do
      client = described_class.new access_token: "some_access_token", token_type: "token_type"
      expect(client.auth.access_token).to eq("some_access_token")
      expect(client.auth.token_type).to eq("token_type")
    end
  end

  it "should NOT refresh the access_token", :vcr do
    client = described_class.new
    old_access_token = client.access_token
    client.refresh_access_token
    # we recently changed the behaviour here, when an access token is still valid, it is returned and NO new token is genereate
    expect(client.access_token).to eq(old_access_token)
  end

  describe 'auto_refresh_access_token', :vcr do
    it "should auto refresh the access_token, when option is set" do
      client = described_class.new access_token: "EXPIRED_TOKEN", token_type: "bearer", auto_refresh_access_token: true
      client.send(test_method, {})
      expect(client.access_token).not_to be_empty
      expect(client.access_token).not_to eq("EXPIRED_TOKEN")
    end

    it "should raise an authentication error, after unsuccessful refresh of the token" do
      AtalogicsApi.configure do |config|
        config.client_id = 'wrong_client_id'
        config.client_secret = 'wrong_client_secret'
      end
      client = described_class.new access_token: "EXPIRED_TOKEN", token_type: "bearer", auto_refresh_access_token: true
      expect {
        client.send(test_method, {})
      }.to raise_error AtalogicsApi::Errors::AuthenticationFailed
    end
  end

  describe 'on_access_token_change', :vcr do
    it "should call the given block, when a token has changed" do
      client = described_class.new access_token: "EXPIRED_TOKEN", token_type: "bearer"
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
