module AtalogicsApi
  module SharedHelpers
    def add_json_header
      self.class.headers 'Accept' => 'application/json'
      self.class.headers 'Content-Type' => 'application/json'
    end

    def raise_if_error(*args)
      code = args.first.code
      raise_error(Errors::AuthenticationFailed, *args) if code==401 || code==403
      raise_error(Errors::ApiError, *args) if code==500

      # raise a generic error for every status code that we don't expect
      # 200 -> get
      # 201 -> post created
      # 400 -> validation of parameters failed
      # 404 -> e.g. city not found
      known_response_codes = [200, 201, 400, 404]
      raise_error(Errors::GenericError, *args) unless known_response_codes.include?(code)
    end

    def raise_error(error_class, response, method, url, options)
      raise(
        error_class,
        response_body: response.body,
        response_code: response.code,
        method: method,
        url: url,
        options: options
      )
    end
  end
end
