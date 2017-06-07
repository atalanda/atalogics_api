module AtalogicsApi
  module V3
    # Base class for all requests to atalogics
    #
    # @author Hubert Hoelzl
    # @attr_reader [AtalogicsApi::Auth] auth The currently used auth instance
    class Client < ClientBase
      private def set_base_uri
        self.class.base_uri(AtalogicsApi.api_url_v3)
      end

      private def namespace_cache_key cache_key
        "V3_#{cache_key}"
      end

      ################################################################
      # Cacheable requests (if cache is configured)
      ################################################################

      # Performs an address check
      # CACHEABLE
      # @param body [Hash] Hash with address parts, see docs
      # @return [HTTParty::Response]
      def offers body
        url = "/offers"
        cache_key = url + "_" + body.sort.map(&:last).join("_")
        perform_api_post(url, body: body.to_json, cache_key: cache_key)
      end

      # Bang method for offers, raises an error when response code != 200
      # CACHEABLE
      # @param body [Hash] Hash with address parts, see docs
      # @return [HTTParty::Response]
      def offers! body
        response = offers body
        raise Response::FailedError.new(response) if response.code != 200
        response
      end

      ################################################################
      # NON-Cacheable requests
      ################################################################

      # Returns all offers that are available, based on the passed body
      # @param body [Hash] Hash with catch and drop information see docs
      # @return [HTTParty::Response]
      def shipments body
        perform_api_post("/shipments", body: body.to_json)
      end
    end
  end
end
