module AtalogicsApi
  module SharedHelpers
    def add_json_header
      self.class.headers 'Accept' => 'application/json'
      self.class.headers 'Content-Type' => 'application/json'
    end

    def raise_if_error response
      code = response.code
      raise Errors::AuthenticationFailed, response.body if code==401 || code==403
      raise Errors::ApiError, response.body if code==500

      # raise a generic error for every status code that we don't expect
      # 200 -> get
      # 201 -> post created
      # 400 -> validation of parameters failed
      # 404 -> e.g. city not found
      known_response_codes = [200, 201, 400, 404]
      raise Errors::GenericError, response.body unless known_response_codes.include?(code)
    end
  end
end
