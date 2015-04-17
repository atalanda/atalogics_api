module AtalogicsApi
  # Base class for all requests to atalogics
  #
  # @author Hubert Hoelzl
  # @attr_reader [AtalogicsApi::Auth] auth The currently used auth instance
  class Client
    include HTTParty
    include HttpartySetup

    attr_reader :auth

    # Initializes a client
    # @param access_token [String, nil] When passed and valid, no new access_token will be generated
    # @return [Client]
    def initialize options={}
      @auth = Auth.new options[:access_token]
      add_json_header
      add_auth_header
      set_base_uri
    end

    # Refreshes the access_token
    # @return [String] an access_token
    def refresh_access_token
      @auth.get_access_token
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
      self.class.post("/addresses/single/check", body: address_parts.to_json)
    end

    # Returns all offers that are available, based on the passed hash
    # @param hash [Hash] Hash with catch and drop information (see https://swagger.atalanda.com/#!/offers/POST_offers_format for all available options)
    # @return [HTTParty::Response]
    def offers hash
      self.class.post("/offers", body: hash.to_json)
    end

    # Purchases a shipment, based on an offer_id
    # @param hash [Hash] Hash with offer_id, catch and drop information (see https://swagger.atalanda.com/#!/shipments/POST_shipments_format for all available options)
    # @return [HTTParty::Response]
    def purchase_offer hash
      self.class.post("/shipments", body: hash.to_json)
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
