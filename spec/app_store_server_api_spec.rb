# frozen_string_literal: true
#== run command
# bundle exec rspec spec/app_store_server_api_spec.rb
#
#== set environment variable
# You need to set values for the environment variables to pass the tests.
# Here is an example using bash.
# The values are just samples and will not work as is.
#
# ```bash
# export issuer_id="13b5ef32-1a08-35a2-e148-5b8c7c11a4d1"
# export key_id="3KB13592P3"
# export private_key=$'-----BEGIN PRIVATE KEY-----\n......\n-----END PRIVATE KEY-----'
# export bundle_id='com.myapp.app'
# export transaction_id='2000000151031281'
# ```
RSpec.describe AppStoreServerApi do

  let(:client) {
    AppStoreServerApi::Client.new(
      private_key: ENV['private_key'],
      key_id: ENV['key_id'],
      issuer_id: ENV['issuer_id'],
      bundle_id: ENV['bundle_id'],
      environment: :sandbox
    )
  }

  describe 'Client' do

    describe '#generate_bearer_token' do

      it 'generate a bearer token' do
        issued_at = Time.now
        expired_in = 600 # 10 minutes
        token = client.generate_bearer_token(issued_at: issued_at, expired_in: expired_in)

        # decode token
        payload, headers = JWT.decode(token, nil, false)
        expect(payload).to match({
          'iss' => client.issuer_id,
          'iat' => issued_at.to_i,
          'exp' => (issued_at + expired_in).to_i,
          'aud' => 'appstoreconnect-v1',
          'bid' => client.bundle_id
        })

        expect(headers).to match({
          'alg' => 'ES256',
          'kid' => client.key_id,
          'typ' => 'JWT'
        })
      end

    end

    describe '#get_transaction_info' do

      let(:transaction_id) {ENV['transaction_id']}

      it 'get information about a single transaction' do
        transaction_info = client.get_transaction_info(transaction_id)
        expect(transaction_info).to be_a Hash
        expect(transaction_info['transactionId']).to eq transaction_id
        expect(transaction_info['bundleId']).to eq client.bundle_id
      end

    end

    describe '#request_test_notification' do

      it 'request a test notification' do
        # response example:
        # {"testNotificationToken"=>"9f90efb9-2f75-4dbe-990c-5d1fc89f4546_1739179413123"}
        result = client.request_test_notification
        expect(result).to be_a Hash
        expect(result.has_key?('testNotificationToken')).to be true
      end

    end

    describe '#get_test_notification_status' do

      it 'get test notification status' do
        # request test a notification
        test_notification_token = client.request_test_notification['testNotificationToken']

        # If you request it immediately you will get a not found error
        # Wait a bit to avoid this
        sleep 1

        # get test notification status
        # response example:
        # {
        #   "signedPayload"=> "eyJhbGciOiJFUzI1NiIsIng1YyI6...",
        #   "firstSendAttemptResult"=>"SUCCESS",
        #   "sendAttempts"=>[{"attemptDate"=>1739179888814, "sendAttemptResult"=>"SUCCESS"}]
        # }
        result = client.get_test_notification_status(test_notification_token)

        expect(result.has_key?('signedPayload')).to be true
        expect(result.has_key?('sendAttempts')).to be true

        payload = AppStoreServerApi::Utils::Decoder.decode_jws!(result['signedPayload'])

        token_uuid = test_notification_token.split('_', 2).first

        # payload example:
        # {
        #   "notificationType"=>"TEST",
        #   "notificationUUID"=>"3838df56-31ab-4e2e-9535-e6e9377c4c77",
        #   "data"=>{"bundleId"=>"com.myapp.app", "environment"=>"Sandbox"},
        #   "version"=>"2.0",
        #   "signedDate"=>1739180480080
        # }
        expect(payload['notificationType']).to eq 'TEST'
        expect(payload['notificationUUID']).to eq token_uuid
        expect(payload['data']['bundleId']).to eq client.bundle_id
        expect(payload['data']['environment']).to eq 'Sandbox'
        expect(payload['version']).to eq '2.0'
        expect(payload['signedDate']).to be_a Integer # Unixtimemillis
      end

    end

  end

end
