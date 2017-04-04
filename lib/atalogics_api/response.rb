module AtalogicsApi
  # Base class for all requests to atalogics
  #
  # @author Hubert Hoelzl
  # @attr_reader [Integer] code HTTP response code
  # @attr_reader [Hash] body Parsed response body
  class Response
    class FailedError < Exception; end

    attr_reader :code, :body
    def initialize code, body
      @code = code
      @body = body
    end

    def to_s
      "#<AtalogicsApi::Response, code: #{code}, body: #{body.to_s}>"
    end
  end
end
