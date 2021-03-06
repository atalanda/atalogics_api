module AtalogicsApi
  # Class that authenticates a with client_id and client_secret.
  # It stores an non permanent access_token
  #
  # @author Hubert Hoelzl
  # @attr_reader [String] access_token An access_token that is included in the headers of further requests
  # @attr_reader [String] token_type Token type of the auth strategy
  # @attr_reader [String] expires_in Expire time in seconds
  # @attr_reader [HTTParty::Response] response Raw http response of the auth process
  class Auth
    include HTTParty
    default_timeout(DEFAULT_TIMEOUT)

    include SharedHelpers
    OAUTH_URL = '/oauth/token'

    attr_reader :access_token, :token_type, :expires_in, :response

    def initialize access_token=nil, token_type=nil
      raise Errors::AccessTokenAndTokenTypeMustBeSet if (access_token && !token_type) || (!access_token && token_type)
      self.class.set_base_uri
      add_json_header
      @token_type = token_type
      @access_token = access_token || refresh_access_token
    end

    def self.set_base_uri
      self.base_uri("#{AtalogicsApi.base_url}#{OAUTH_URL}")
      self.base_uri
    end

    def refresh_access_token
      body = {
        client_id: AtalogicsApi.client_id,
        client_secret: AtalogicsApi.client_secret,
        grant_type: 'client_credentials'
      }.to_json

      response = self.class.post('', {body: body})

      raise Errors::AuthenticationFailed if response.code==401
      raise Errors::ApiError, "An error occured. Response: #{response}" if response.code!=200

      @response = response
      @access_token = response["access_token"]
      @token_type = response["token_type"]
      @expires_in = response["expires_in"]

      return @access_token
    end
  end
end
