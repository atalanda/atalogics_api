# frozen_string_literal: true

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

      private def namespace_cache_key(cache_key)
        "V3_#{cache_key}"
      end

      ################################################################
      # Cacheable requests (if cache is configured)
      ################################################################

      # Performs an address check
      # CACHEABLE
      # @param body [Hash] Hash with address parts, see docs
      # @return [HTTParty::Response]
      def offers(body)
        url = "/offers"
        cache_key = url + "_" + body.sort.map(&:last).join("_")
        post(url, body: body.to_json, cache_key: cache_key, expired?: offer_expired?)
      end

      private def offer_expired?
        ->(cached_result) {
          return true unless cached_result
          return true unless offer = cached_result.body["offers"].first

          # a cached result expires when the current Time is
          # after the first offer["catch_window"]["usable_till"]
          Time.now > Time.parse(offer.fetch("catch_window").fetch("usable_till"))
        }
      end

      # Bang method for offers, raises an error when response code != 200
      # CACHEABLE
      # @param body [Hash] Hash with address parts, see docs
      # @return [HTTParty::Response]
      def offers!(body)
        response = offers body
        if response.code != 200
          raise_error(Response::FailedError, response, :post, "/offers", body: body)
        end
        response
      end

      # Returns delivery areas of a given city
      # CACHEABLE
      # @param key [String] String containing an atalogics city key, see docs
      # @return [HTTParty::Response]
      def delivery_areas(key)
        url = "/cities/#{key}"
        get(url, cache_key: url, expires_in: EXPIRES_IN_1_HOUR)
      end

      ################################################################
      # NON-Cacheable requests
      ################################################################

      # Returns all offers that are available, based on the passed body
      # @param body [Hash] Hash with catch and drop information see docs
      # @return [HTTParty::Response]
      def shipments(body)
        post("/shipments", body: body.to_json)
      end
    end
  end
end
