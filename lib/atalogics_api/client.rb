module AtalogicsApi
  # Base class for all requests to atalogics
  #
  # @author Hubert Hoelzl
  # @attr [Types] attribute_name a full description of the attribute
  # @attr_reader [Types] name description of a readonly attribute
  # @attr_writer [Types] name description of writeonly attribute
  class Client
    include HTTParty
    include HttpartySetup

    # Initializes a client
    # @param access_token [String, nil] When passed and valid, no new access_token will be generated
    # @return [Client]
    def initialize access_token=nil
      @auth = Auth.new access_token
      add_json_header
      add_auth_header
      set_base_uri
      refresh_auth_token
    end

    # Performs an address check
    # @param address_parts [Hash] Hash with address parts
    # @option address_parts [String] :street A street
    # @option address_parts [String] :postal_code A postal or zip code
    # @option address_parts [String] :city Name of the city
    # @return [HTTParty::Response]
    def address_check address_parts
      self.class.post("/addresses/single/check", body: address_parts.to_json, headers: {})
    end

    private
    def set_base_uri
      self.class.base_uri(AtalogicsApi.api_url)
    end

    def refresh_auth_token
      @auth.get_auth_token
      add_auth_header
    end

    def add_auth_header
      self.class.headers.delete("Authorization")
      self.class.headers 'Authorization' => "#{@auth.token_type} #{@auth.access_token}"
    end
  end
end
