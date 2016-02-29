module AtalogicsApi
  # Base class for all requests to atalogics
  #
  # @author Hubert Hoelzl
  # @attr_reader [AtalogicsApi::Auth] auth The currently used auth instance
  class Client
    include HTTParty
    include SharedHelpers

    attr_reader :auth

    # Initializes a client
    # @param options [Hash] options Hash
    # @option options [String] :access_token Optional access_token to re-use
    # @option options [String] :token_type Optional token_type to re-use
    # @option options [Boolean] :auto_refresh_access_token When set to true, it will automatically refresh the access_token, onece it has expired or is revoked
    # @return [Client]
    def initialize options={}
      @auth = Auth.new options[:access_token], options[:token_type]
      @auto_refresh_access_token = options[:auto_refresh_access_token] || false
      add_json_header
      add_auth_header
      set_base_uri
    end

    # Refreshes the access_token
    # @return [String] an access_token
    def refresh_access_token
      @auth.refresh_access_token
      add_auth_header

      if @token_callback
        @token_callback.call(@auth.access_token, @auth.token_type, @auth.expires_in)
      end

      @auth.access_token
    end

    # Calls the given block, when the token has changed
    # @param callback [Proc] A block that is called, when the token has changed
    def on_access_token_change &callback
      @token_callback = callback
    end

    # Returns the access_token from the auth class
    # @return [String] an access_token
    def access_token
      auth.access_token
    end

    ################################################################
    # Cacheable requests (if cache is configured)
    ################################################################

    # Performs an address check
    # CACHEABLE
    # @param parts [Hash] Hash with address parts
    # @option parts [String] :street A street
    # @option parts [String] :number A street number
    # @option parts [String] :postal_code A postal or zip code
    # @option parts [String] :city Name of the city
    # @return [HTTParty::Response]
    def address_check parts
      url = "/addresses/single/check"
      cache_key = "#{url}_#{parts[:street]}_#{parts[:number]}_#{parts[:postal_code]}_#{parts[:city]}"
      perform_api_post(url, body: parts.to_json, cache_key: cache_key)
    end

    # Wrapper for address check, which returns just a boolean value
    # CACHEABLE through address_check endpoint
    # @param parts [Hash] Hash with address parts
    # @option parts [String] :street A street
    # @option parts [String] :number A street number
    # @option parts [String] :postal_code A postal or zip code
    # @option parts [String] :city Name of the city
    # @return [Boolean]
    def in_delivery_range? parts
      response = address_check(parts)
      return false unless response
      response.body["success"]
    end

    # Lists available shipping
    # CACHEABLE
    # @param body [Hash] Hash containing {address: "..."} or {lat: 1.1, lng: 2.2}
    # @return [HTTParty::Response]
    def next_delivery_time body
      url = "/next_delivery_time"
      if body[:position]
        cache_key = "#{url}_#{body[:position][:lat]}_#{body[:position][:lng]}"
      else
        cache_key = "#{url}_#{body[:address]}"
      end

      perform_api_post url, body: body.to_json, cache_key: cache_key, expired?: ->(cached_result) {
        # a cached result expires when the current Time is after catch time to
        cached_result && Time.now > Time.parse(cached_result.body["catch_time_window"]["to"])
      }
    end

    ################################################################
    # NON-Cacheable requests
    ################################################################

    # Returns all offers that are available, based on the passed body
    # @param body [Hash] Hash with catch and drop information (see https://swagger.atalanda.com/#!/offers/POST_offers_format for all available options)
    # @return [HTTParty::Response]
    def offers body
      perform_api_post("/offers", body: body.to_json)
    end

    # Purchases a shipment, based on an offer_id
    # @param body [Hash] Hash with offer_id, catch and drop information (see https://swagger.atalanda.com/#!/shipments/POST_shipments_format for all available options)
    # @return [HTTParty::Response]
    def purchase_offer body
      perform_api_post("/shipments", body: body.to_json)
    end

    private
    def perform_api_post *args, &block
      cache_key = args[1].delete(:cache_key)
      if cache_key
        response = get_cached_result(cache_key)
        expired_block = args[1].delete(:expired?)
        expired = expired_block.call(response) if expired_block
        return response if response && !expired
      end

      response = perform_api_request(:post, *args, &block)
      store_cached_result(cache_key, response.code, response.body) if cache_key
      response
    end

    def perform_api_request method, *args, &block
      response = self.class.send(method, *args)
      response = AtalogicsApi::Response.new(response.code, response.parsed_response)

      catch(:access_token_refreshed) do
        check_response(response)
        return response
      end

      perform_api_request(method, *args) # perform again with refreshed access_token
    end

    def check_response response, &block
      raise_if_error response
    rescue Errors::AuthenticationFailed => e
      if @auto_refresh_access_token
        refresh_access_token
        throw(:access_token_refreshed)
      end
      raise_if_error response
    end

    def get_cached_result key
      return unless AtalogicsApi.cache_store
      return unless cached_response = AtalogicsApi.cache_store.get(key)
      # 0 => code, 1 => body as json
      response = JSON.parse(cached_response)
      AtalogicsApi::Response.new response[0], response[1]
    end

    def store_cached_result key, code, hash
      return if code.to_s[0]!="2" && code.to_s[0]!="3" # don't cache failed responses
      return unless AtalogicsApi.cache_store
      AtalogicsApi.cache_store.set key, [code, hash].to_json
      AtalogicsApi.cache_store.expire key, 24*60*60 # 24 hours
    end

    def set_base_uri
      self.class.base_uri(AtalogicsApi.api_url)
    end

    def add_auth_header
      self.class.headers.delete("Authorization")
      self.class.headers 'Authorization' => "#{@auth.token_type} #{@auth.access_token}"
    end
  end
end
