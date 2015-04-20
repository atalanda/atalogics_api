module AtalogicsApi
  module SharedHelpers
    def add_json_header
      self.class.headers 'Accept' => 'application/json'
      self.class.headers 'Content-Type' => 'application/json'
    end

    def raise_if_error response
      code = response.code
      raise Errors::AuthenticationFailed.new(response.body) if code==401 || code==403
      raise Errors::ApiError.new(response.body) if code==500
      response
    end
  end
end
