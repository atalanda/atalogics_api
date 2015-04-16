module AtalogicsApi
  class Auth
    class AuthenticationFailed < StandardError; end
    class ApiError < StandardError; end

    include HTTParty
    include HttpartySetup
    OAUTH_URL = '/oauth/token'

    attr_reader :access_token, :token_type, :expires_in, :response, :code

    def initialize access_token=nil
      self.class.set_base_uri
      setup_httparty
      @access_token = access_token || get_auth_token
    end

    def self.set_base_uri
      self.base_uri("#{AtalogicsApi.base_url}#{OAUTH_URL}")
      self.base_uri
    end

    def get_auth_token
      body = {
        client_id: AtalogicsApi.client_id,
        client_secret: AtalogicsApi.client_secret,
        grant_type: 'client_credentials'
      }.to_json

      response = self.class.post('', {body: body})

      raise AuthenticationFailed if response.code==401
      raise ApiError, "An error occured. Response: #{response}" if response.code!=200

      @response = response.to_hash
      @code = response.code
      @access_token = response["access_token"]
      @token_type = response["token_type"]
      @expires_in = response["expires_in"]

      return @access_token
    end
  end
end
