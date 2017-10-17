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
        perform_cached_api_request url, method: :post, body: body.to_json, cache_key: cache_key, expired?: ->(cached_result) {
          # a cached result expires when the current Time is after the first offer["catch_window"]["usable_till"]
          cached_result && Time.now > Time.parse(cached_result.body["offers"].first["catch_window"]["usable_till"])
        }
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

      # Returns delivery areas of a given city
      # CACHEABLE
      # @param key [String] String containing an atalogics city key, see docs
      # @return [HTTParty::Response]
      def delivery_areas key
        url = "/cities/#{key}"
        perform_cached_api_request(url, {
          method: :get,
          cache_key: url,
          expires_at: (Time.now + 8 * 60 * 60).to_i,
          expired?: lambda do |cached_result|
            cached_result && Time.now.to_i > cached_result.body["expires_at"]
          end
        })
      end

      ################################################################
      # NON-Cacheable requests
      ################################################################

      # Returns all offers that are available, based on the passed body
      # @param body [Hash] Hash with catch and drop information see docs
      # @return [HTTParty::Response]
      def shipments body
        perform_cached_api_request("/shipments", method: :post, body: body.to_json)
      end
    end
  end
end
