module AtalogicsApi
  module V2
    # Base class for all requests to atalogics
    #
    # @author Hubert Hoelzl
    # @attr_reader [AtalogicsApi::Auth] auth The currently used auth instance
    class Client < ClientBase
      private def set_base_uri
        self.class.base_uri(AtalogicsApi.api_url_v2)
      end

      private def namespace_cache_key cache_key
        "V2_#{cache_key}"
      end

      ################################################################
      # Cacheable requests (if cache is configured)
      ################################################################

      # Performs an address check
      # CACHEABLE
      # @param parts [Hash] Hash with address parts, see docs
      # @return [HTTParty::Response]
      def address_check parts
        url = "/addresses/single/check"
        cache_key = "#{url}_#{parts[:street]}_#{parts[:number]}_#{parts[:postal_code]}_#{parts[:city]}_#{parts[:lat]}_#{parts[:lng]}"
        perform_api_post(url, body: parts.to_json, cache_key: cache_key)
      end

      # Performs an address check
      # CACHEABLE
      # @param addresses [Array] Array of hashes of address parts
      # @return [HTTParty::Response]
      def multi_address_check addresses
        url = "/addresses/multi/check"
        cache_key = "#{url}"
        addresses[:addresses].each do |address|
          cache_key += "_#{address[:street]}_#{address[:number]}_#{address[:postal_code]}_#{address[:city]}_#{address[:lat]}_#{address[:lng]}"
        end
        perform_api_post(url, body: addresses.to_json, cache_key: cache_key)
      end

      # Wrapper for address check, which returns just a boolean value
      # CACHEABLE through address_check endpoint
      # @param parts [Hash] Hash with address parts
      # @return [Boolean]
      def in_delivery_range? parts
        response = address_check(parts)
        return false unless response
        response.body["success"]
      end

      # Lists available timeslots
      # CACHEABLE
      # @param body [Hash] Hash containing {address: "..."} or {lat: 1.1, lng: 2.2}
      # @return [HTTParty::Response]
      def next_timeslots body
        url = "/next_timeslots"
        if body[:position]
          cache_key = "#{url}_#{body[:position][:lat]}_#{body[:position][:lng]}"
        else
          cache_key = "#{url}_#{body[:address]}"
        end

        cache_key += "_from_#{body[:from]}" if body[:from]
        cache_key += "_to_#{body[:to]}" if body[:to]

        perform_api_post url, body: body.to_json, cache_key: cache_key, expired?: ->(cached_result) {
          # a cached result expires when the current Time is after the first catch timeslots' bookable_till
          cached_result && Time.now > Time.parse(cached_result.body.first["catch_time_window"]["bookable_till"])
        }
      end

      # Bang method for next_timeslots, raises an error when response code != 200
      # CACHEABLE
      # @param body [Hash] Hash containing {address: "..."} or {lat: 1.1, lng: 2.2}
      # @return [HTTParty::Response]
      def next_timeslots! body
        response = next_timeslots body
        raise Response::FailedError.new(response) if response.code != 200
        response
      end

      ################################################################
      # NON-Cacheable requests
      ################################################################

      # Returns all offers that are available, based on the passed body
      # @param body [Hash] Hash with catch and drop information see docs
      # @return [HTTParty::Response]
      def offers body
        perform_api_post("/offers", body: body.to_json)
      end

      # Purchases a shipment, based on an offer_id
      # @param body [Hash] Hash with offer_id, catch and drop information, see docs
      # @return [HTTParty::Response]
      def purchase_offer body
        perform_api_post("/shipments", body: body.to_json)
      end

    end
  end
end
