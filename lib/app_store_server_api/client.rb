# frozen_string_literal: true
require "jwt"
require 'faraday'
require "uri"
require "json"
require "openssl"

module AppStoreServerApi

  class Client
    attr_reader :environment, :issuer_id, :key_id, :private_key, :bundle_id

    PAYLOAD_AUD = 'appstoreconnect-v1'
    TOKEN_TYPE = 'JWT'
    ENCODE_ALGORITHM = 'ES256'
    API_BASE_URLS = {
      :production => 'https://api.storekit.itunes.apple.com',
      :sandbox => 'https://api.storekit-sandbox.itunes.apple.com'
    }.freeze

    # initialize client
    # @param private_key [String] p8 key
    # @param key_id [String] Your private key ID from App Store Connect (Ex: 2X9R4HXF34)
    # @param issuer_id [String] Your issuer ID from the Keys page in App Store Connect
    # @param bundle_id [String] Your app’s bundle ID (Ex: “com.example.testbundleid”)
    # @param environment [Symbol] :production or :sandbox
    def initialize(private_key:, key_id:, issuer_id:, bundle_id:, environment: :production)
      unless [:production, :sandbox].include?(environment)
        raise ArgumentError, 'environment must be :production or :sandbox'
      end

      @environment = environment
      @issuer_id = issuer_id
      @key_id = key_id
      @private_key = private_key
      @bundle_id = bundle_id
    end

    # get information about a single transaction
    # @see https://developer.apple.com/documentation/appstoreserverapi/get-v1-transactions-_transactionid_
    # @param [String] transaction_id The identifier of a transaction
    # @return [Hash] transaction info
    def get_transaction_info(transaction_id)
      path = "/inApps/v1/transactions/#{transaction_id}"
      response = do_get(path)

      if response.success?
        json = JSON.parse(response.body)
        payload, = Utils::Decoder.decode_jws!(json['signedTransactionInfo'])
        payload
      else
        raise Error.parse_response(response)
      end
    end

    # generate bearer token
    # @param issued_at [Time] issued at
    # @param expired_in [Integer] expired in seconds (max 3600)
    # @return [String] bearer token
    def generate_bearer_token(issued_at: Time.now, expired_in: 3600)
      # expirations longer than 60 minutes will be rejected
      if expired_in > 3600
        raise ArgumentError, 'expired_in must be less than or equal to 3600'
      end

      headers = {
        alg: ENCODE_ALGORITHM,
        kid: key_id,
        typ: TOKEN_TYPE,
      }

      payload = {
        iss: issuer_id,
        iat: issued_at.to_i,
        exp: (issued_at + expired_in).to_i,
        aud: PAYLOAD_AUD,
        bid: bundle_id
      }

      JWT.encode(payload, OpenSSL::PKey::EC.new(private_key), ENCODE_ALGORITHM, headers)
    end

    def api_base_url
      API_BASE_URLS[environment]
    end

    def base_request_headers(bearer_token)
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{bearer_token}"
      }
    end

    # send get request to App Store Server API
    # @param [String] path request path (ex: '/inApps/v1/transactions/2000000847061981')
    # @param [Hash] params request params
    # @param [Hash] headers additional headers
    # @return [Faraday::Response] response
    def do_get(path, params: {}, headers: {}, open_timeout: 10, read_timeout: 30)
      request_url = api_base_url + path
      bearer_token = generate_bearer_token
      request_headers = base_request_headers(bearer_token).merge(headers)

      conn = Faraday.new do |f|
        f.adapter :net_http do |http|
          http.open_timeout = 10
          http.read_timeout = 30
        end
      end

      conn.get(request_url, params, request_headers)
    end

  end

end