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
    # @option options [String] :access_token Optional access_token to re-used
    # @option options [Boolean] :auto_refresh_access_token When set to true, it will automatically refresh the access_token, onece it has expired or is revoked
    # @return [Client]
    def initialize options={}
      @auth = Auth.new options[:access_token]
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
      @auth.access_token
    end

    # Returns the access_token from the auth class
    # @return [String] an access_token
    def access_token
      auth.access_token
    end

    # Performs an address check
    # @param address_parts [Hash] Hash with address parts
    # @option address_parts [String] :street A street
    # @option address_parts [String] :postal_code A postal or zip code
    # @option address_parts [String] :city Name of the city
    # @return [HTTParty::Response]
    def address_check address_parts
      perform_api_action("/addresses/single/check", body: address_parts.to_json)
    end

    # Wrapper for address check, which returns just a boolean value
    # @param address_parts [Hash] Hash with address parts
    # @option address_parts [String] :street A street
    # @option address_parts [String] :postal_code A postal or zip code
    # @option address_parts [String] :city Name of the city
    # @return [Boolean]
    def in_delivery_range? address_parts
      response = address_check(address_parts)
      return false unless response
      response["success"]
    end

    # Returns all offers that are available, based on the passed hash
    # @param hash [Hash] Hash with catch and drop information (see https://swagger.atalanda.com/#!/offers/POST_offers_format for all available options)
    # @return [HTTParty::Response]
    def offers hash
      perform_api_action("/offers", body: hash.to_json)
    end

    # Purchases a shipment, based on an offer_id
    # @param hash [Hash] Hash with offer_id, catch and drop information (see https://swagger.atalanda.com/#!/shipments/POST_shipments_format for all available options)
    # @return [HTTParty::Response]
    def purchase_offer hash
      perform_api_action("/shipments", body: hash.to_json)
    end

    def perform_api_action *args
      response = self.class.post(*args)
      begin
        raise_if_error response
      rescue Errors::AuthenticationFailed => e
        if @auto_refresh_access_token
          refresh_access_token
          response = self.class.post(*args)
        end
        raise_if_error response
      end
      response
    end

    private
    def set_base_uri
      self.class.base_uri(AtalogicsApi.api_url)
    end

    def add_auth_header
      self.class.headers.delete("Authorization")
      self.class.headers 'Authorization' => "#{@auth.token_type} #{@auth.access_token}"
    end
  end
end
