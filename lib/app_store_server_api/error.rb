# frozen_string_literal: true
module AppStoreServerApi

  class Error < StandardError
    attr_reader :response, :message, :code

    # @param [String] code error code
    # @param [String] message error message
    # @param [Faraday::Response] response original response
    def initialize(code:, message:, response:)
      super(message)
      @code = code
      @response = response
    end

    # parse error response
    # @param [Faraday::Response] response
    def self.parse_response(response)
      unless response.is_a?(Faraday::Response)
        raise ArgumentError, 'response must be a Faraday::Response'
      end

      error = JSON.parse(response.body)
      attrs = {
        message: error['errorMessage'],
        code: error['errorCode'],
        response: response
      }

      case response.status
      when 400
        BadRequest.new(**attrs)
      when 401
        UnauthorizedError.new(**attrs)
      when 404
        NotFound.new(**attrs)
      when 429
        RateLimitExceededError.new(**attrs)
      when 500
        ServerError.new(**attrs)
      else
        UnexpectedError.new(**attrs)
      end
    end

    # The JSON Web Token (JWT) in the authorization header is invalid. For more information
    # @see https://developer.apple.com/documentation/appstoreserverapi/generating-json-web-tokens-for-api-requests
    class UnauthorizedError < Error; end

    class BadRequest < Error; end

    class RateLimitExceededError < Error; end

    class NotFound < Error; end

    class ServerError < Error; end

    class UnexpectedError < Error; end

  end

end