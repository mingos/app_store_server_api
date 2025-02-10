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

  end

end