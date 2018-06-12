# frozen_string_literal: true

module AtalogicsApi
  class ClientBase
    include HTTParty
    default_timeout(DEFAULT_TIMEOUT)

    include SharedHelpers

    EXPIRES_IN_1_HOUR = 60 * 60
    EXPIRES_IN_24_HOURS = 24 * EXPIRES_IN_1_HOUR

    attr_reader :auth

    # Initializes a client
    # @param options [Hash] options Hash
    # @option options [String] :access_token Optional access_token to re-use
    # @option options [String] :token_type Optional token_type to re-use
    # @option options [Boolean] :auto_refresh_access_token When set to true, it will automatically refresh the access_token, onece it has expired or is revoked
    # @return [Client]
    def initialize(options = {})
      set_base_uri
      @auth = Auth.new options[:access_token], options[:token_type]
      @auto_refresh_access_token = options[:auto_refresh_access_token] || false
      add_json_header
      add_auth_header
    end

    private def set_base_uri
      raise NotImplementedError
    end

    private def namespace_cache_key(_cache_key)
      raise NotImplementedError
    end

    # Refreshes the access_token
    # @return [String] an access_token
    def refresh_access_token
      @auth.refresh_access_token
      add_auth_header

      @token_callback&.call(@auth.access_token, @auth.token_type, @auth.expires_in)

      @auth.access_token
    end

    # Calls the given block, when the token has changed
    # @param callback [Proc] A block that is called, when the token has changed
    def on_access_token_change(&callback)
      @token_callback = callback
    end

    # Returns the access_token from the auth class
    # @return [String] an access_token
    def access_token
      auth.access_token
    end

    private def get(url, options = {}, &block)
      perform(url, :get, options, &block)
    end

    private def post(url, options = {}, &block)
      perform(url, :post, options, &block)
    end

    private def perform(url, method, options, &block)
      if cache_key = options.delete(:cache_key)
        cache_key = namespace_cache_key(cache_key)
        response = get_cached_result(cache_key)
        expired = options.delete(:expired?)&.call(response)
        return response if response && !expired
      end

      response = perform_http_request(method, url, options, &block)

      expires_in = options.fetch(:expires_in, EXPIRES_IN_24_HOURS)
      store_cached_result(cache_key, response.code, response.body, expires_in) if cache_key
      response
    end

    private def perform_http_request(method, url, options)
      response = self.class.send(method, url, options)
      response = AtalogicsApi::Response.new(response.code, response.parsed_response)

      catch(:access_token_refreshed) do
        check_response(response, method, url, options)
        return response
      end

      perform_http_request(method, url, options) # perform again with refreshed access_token
    end

    private def check_response(*args)
      raise_if_error(*args)
    rescue Errors::AuthenticationFailed
      if @auto_refresh_access_token
        refresh_access_token
        throw(:access_token_refreshed)
      end
      raise_if_error(*args)
    end

    private def get_cached_result(key)
      return unless AtalogicsApi.cache_store
      return unless cached_response = AtalogicsApi.cache_store.get(key)
      # 0 => code, 1 => body as json
      response = JSON.parse(cached_response)
      AtalogicsApi::Response.new response[0], response[1]
    end

    private def store_cached_result(key, code, hash, expires_in)
      return if code.to_s[0] != "2" && code.to_s[0] != "3" # don't cache failed responses
      return unless AtalogicsApi.cache_store
      AtalogicsApi.cache_store.set key, [code, hash].to_json
      AtalogicsApi.cache_store.expire key, expires_in
    end

    private def add_auth_header
      self.class.headers.delete("Authorization")
      self.class.headers "Authorization" => "#{@auth.token_type} #{@auth.access_token}"
    end
  end
end
