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
  it 'has a version number' do
    expect(AppStoreServerApi::VERSION).not_to be nil
  end

  describe 'Client' do
    let(:client) {
      AppStoreServerApi::Client.new(
        private_key: ENV['private_key'],
        key_id: ENV['key_id'],
        issuer_id: ENV['issuer_id'],
        bundle_id: ENV['bundle_id'],
        environment: :sandbox
      )
    }

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

  # Utils::Decoder
  describe AppStoreServerApi::Utils::Decoder do

    # decode_jws!
    describe '#decode_jws!' do

      it 'decode a signed JWT' do
        # my app's sandbox purchase transaction info
        signed_jwt = 'eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlFTURDQ0E3YWdBd0lCQWdJUWZUbGZkMGZOdkZXdnpDMVlJQU5zWGpBS0JnZ3Foa2pPUFFRREF6QjFNVVF3UWdZRFZRUURERHRCY0hCc1pTQlhiM0pzWkhkcFpHVWdSR1YyWld4dmNHVnlJRkpsYkdGMGFXOXVjeUJEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURUxNQWtHQTFVRUN3d0NSell4RXpBUkJnTlZCQW9NQ2tGd2NHeGxJRWx1WXk0eEN6QUpCZ05WQkFZVEFsVlRNQjRYRFRJek1Ea3hNakU1TlRFMU0xb1hEVEkxTVRBeE1URTVOVEUxTWxvd2daSXhRREErQmdOVkJBTU1OMUJ5YjJRZ1JVTkRJRTFoWXlCQmNIQWdVM1J2Y21VZ1lXNWtJR2xVZFc1bGN5QlRkRzl5WlNCU1pXTmxhWEIwSUZOcFoyNXBibWN4TERBcUJnTlZCQXNNSTBGd2NHeGxJRmR2Y214a2QybGtaU0JFWlhabGJHOXdaWElnVW1Wc1lYUnBiMjV6TVJNd0VRWURWUVFLREFwQmNIQnNaU0JKYm1NdU1Rc3dDUVlEVlFRR0V3SlZVekJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUFCRUZFWWUvSnFUcXlRdi9kdFhrYXVESENTY1YxMjlGWVJWLzB4aUIyNG5DUWt6UWYzYXNISk9OUjVyMFJBMGFMdko0MzJoeTFTWk1vdXZ5ZnBtMjZqWFNqZ2dJSU1JSUNCREFNQmdOVkhSTUJBZjhFQWpBQU1COEdBMVVkSXdRWU1CYUFGRDh2bENOUjAxREptaWc5N2JCODVjK2xrR0taTUhBR0NDc0dBUVVGQndFQkJHUXdZakF0QmdnckJnRUZCUWN3QW9ZaGFIUjBjRG92TDJObGNuUnpMbUZ3Y0d4bExtTnZiUzkzZDJSeVp6WXVaR1Z5TURFR0NDc0dBUVVGQnpBQmhpVm9kSFJ3T2k4dmIyTnpjQzVoY0hCc1pTNWpiMjB2YjJOemNEQXpMWGQzWkhKbk5qQXlNSUlCSGdZRFZSMGdCSUlCRlRDQ0FSRXdnZ0VOQmdvcWhraUc5Mk5rQlFZQk1JSCtNSUhEQmdnckJnRUZCUWNDQWpDQnRneUJzMUpsYkdsaGJtTmxJRzl1SUhSb2FYTWdZMlZ5ZEdsbWFXTmhkR1VnWW5rZ1lXNTVJSEJoY25SNUlHRnpjM1Z0WlhNZ1lXTmpaWEIwWVc1alpTQnZaaUIwYUdVZ2RHaGxiaUJoY0hCc2FXTmhZbXhsSUhOMFlXNWtZWEprSUhSbGNtMXpJR0Z1WkNCamIyNWthWFJwYjI1eklHOW1JSFZ6WlN3Z1kyVnlkR2xtYVdOaGRHVWdjRzlzYVdONUlHRnVaQ0JqWlhKMGFXWnBZMkYwYVc5dUlIQnlZV04wYVdObElITjBZWFJsYldWdWRITXVNRFlHQ0NzR0FRVUZCd0lCRmlwb2RIUndPaTh2ZDNkM0xtRndjR3hsTG1OdmJTOWpaWEowYVdacFkyRjBaV0YxZEdodmNtbDBlUzh3SFFZRFZSME9CQllFRkFNczhQanM2VmhXR1FsekUyWk9FK0dYNE9vL01BNEdBMVVkRHdFQi93UUVBd0lIZ0RBUUJnb3Foa2lHOTJOa0Jnc0JCQUlGQURBS0JnZ3Foa2pPUFFRREF3Tm9BREJsQWpFQTh5Uk5kc2twNTA2REZkUExnaExMSndBdjVKOGhCR0xhSThERXhkY1BYK2FCS2pqTzhlVW85S3BmcGNOWVVZNVlBakFQWG1NWEVaTCtRMDJhZHJtbXNoTnh6M05uS20rb3VRd1U3dkJUbjBMdmxNN3ZwczJZc2xWVGFtUllMNGFTczVrPSIsIk1JSURGakNDQXB5Z0F3SUJBZ0lVSXNHaFJ3cDBjMm52VTRZU3ljYWZQVGp6Yk5jd0NnWUlLb1pJemowRUF3TXdaekViTUJrR0ExVUVBd3dTUVhCd2JHVWdVbTl2ZENCRFFTQXRJRWN6TVNZd0pBWURWUVFMREIxQmNIQnNaU0JEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURVRNQkVHQTFVRUNnd0tRWEJ3YkdVZ1NXNWpMakVMTUFrR0ExVUVCaE1DVlZNd0hoY05NakV3TXpFM01qQXpOekV3V2hjTk16WXdNekU1TURBd01EQXdXakIxTVVRd1FnWURWUVFERER0QmNIQnNaU0JYYjNKc1pIZHBaR1VnUkdWMlpXeHZjR1Z5SUZKbGJHRjBhVzl1Y3lCRFpYSjBhV1pwWTJGMGFXOXVJRUYxZEdodmNtbDBlVEVMTUFrR0ExVUVDd3dDUnpZeEV6QVJCZ05WQkFvTUNrRndjR3hsSUVsdVl5NHhDekFKQmdOVkJBWVRBbFZUTUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUVic1FLQzk0UHJsV21aWG5YZ3R4emRWSkw4VDBTR1luZ0RSR3BuZ24zTjZQVDhKTUViN0ZEaTRiQm1QaENuWjMvc3E2UEYvY0djS1hXc0w1dk90ZVJoeUo0NXgzQVNQN2NPQithYW85MGZjcHhTdi9FWkZibmlBYk5nWkdoSWhwSW80SDZNSUgzTUJJR0ExVWRFd0VCL3dRSU1BWUJBZjhDQVFBd0h3WURWUjBqQkJnd0ZvQVV1N0Rlb1ZnemlKcWtpcG5ldnIzcnI5ckxKS3N3UmdZSUt3WUJCUVVIQVFFRU9qQTRNRFlHQ0NzR0FRVUZCekFCaGlwb2RIUndPaTh2YjJOemNDNWhjSEJzWlM1amIyMHZiMk56Y0RBekxXRndjR3hsY205dmRHTmhaek13TndZRFZSMGZCREF3TGpBc29DcWdLSVltYUhSMGNEb3ZMMk55YkM1aGNIQnNaUzVqYjIwdllYQndiR1Z5YjI5MFkyRm5NeTVqY213d0hRWURWUjBPQkJZRUZEOHZsQ05SMDFESm1pZzk3YkI4NWMrbGtHS1pNQTRHQTFVZER3RUIvd1FFQXdJQkJqQVFCZ29xaGtpRzkyTmtCZ0lCQkFJRkFEQUtCZ2dxaGtqT1BRUURBd05vQURCbEFqQkFYaFNxNUl5S29nTUNQdHc0OTBCYUI2NzdDYUVHSlh1ZlFCL0VxWkdkNkNTamlDdE9udU1UYlhWWG14eGN4ZmtDTVFEVFNQeGFyWlh2TnJreFUzVGtVTUkzM3l6dkZWVlJUNHd4V0pDOTk0T3NkY1o0K1JHTnNZRHlSNWdtZHIwbkRHZz0iLCJNSUlDUXpDQ0FjbWdBd0lCQWdJSUxjWDhpTkxGUzVVd0NnWUlLb1pJemowRUF3TXdaekViTUJrR0ExVUVBd3dTUVhCd2JHVWdVbTl2ZENCRFFTQXRJRWN6TVNZd0pBWURWUVFMREIxQmNIQnNaU0JEWlhKMGFXWnBZMkYwYVc5dUlFRjFkR2h2Y21sMGVURVRNQkVHQTFVRUNnd0tRWEJ3YkdVZ1NXNWpMakVMTUFrR0ExVUVCaE1DVlZNd0hoY05NVFF3TkRNd01UZ3hPVEEyV2hjTk16a3dORE13TVRneE9UQTJXakJuTVJzd0dRWURWUVFEREJKQmNIQnNaU0JTYjI5MElFTkJJQzBnUnpNeEpqQWtCZ05WQkFzTUhVRndjR3hsSUVObGNuUnBabWxqWVhScGIyNGdRWFYwYUc5eWFYUjVNUk13RVFZRFZRUUtEQXBCY0hCc1pTQkpibU11TVFzd0NRWURWUVFHRXdKVlV6QjJNQkFHQnlxR1NNNDlBZ0VHQlN1QkJBQWlBMklBQkpqcEx6MUFjcVR0a3lKeWdSTWMzUkNWOGNXalRuSGNGQmJaRHVXbUJTcDNaSHRmVGpqVHV4eEV0WC8xSDdZeVlsM0o2WVJiVHpCUEVWb0EvVmhZREtYMUR5eE5CMGNUZGRxWGw1ZHZNVnp0SzUxN0lEdll1VlRaWHBta09sRUtNYU5DTUVBd0hRWURWUjBPQkJZRUZMdXczcUZZTTRpYXBJcVozcjY5NjYvYXl5U3JNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEZ1lEVlIwUEFRSC9CQVFEQWdFR01Bb0dDQ3FHU000OUJBTURBMmdBTUdVQ01RQ0Q2Y0hFRmw0YVhUUVkyZTN2OUd3T0FFWkx1Tit5UmhIRkQvM21lb3locG12T3dnUFVuUFdUeG5TNGF0K3FJeFVDTUcxbWloREsxQTNVVDgyTlF6NjBpbU9sTTI3amJkb1h0MlFmeUZNbStZaGlkRGtMRjF2TFVhZ002QmdENTZLeUtBPT0iXX0.eyJ0cmFuc2FjdGlvbklkIjoiMjAwMDAwMDg0NzA2MTk4MSIsIm9yaWdpbmFsVHJhbnNhY3Rpb25JZCI6IjIwMDAwMDA4NDcwNjE5ODEiLCJidW5kbGVJZCI6ImNvbS5nb29kaGVhcnRhcHAiLCJwcm9kdWN0SWQiOiJnaF9zdXBlcl9nb29kX3RpY2tldF8xIiwicHVyY2hhc2VEYXRlIjoxNzM4NjQ1NTYwMDAwLCJvcmlnaW5hbFB1cmNoYXNlRGF0ZSI6MTczODY0NTU2MDAwMCwicXVhbnRpdHkiOjEsInR5cGUiOiJDb25zdW1hYmxlIiwiaW5BcHBPd25lcnNoaXBUeXBlIjoiUFVSQ0hBU0VEIiwic2lnbmVkRGF0ZSI6MTczOTE2MTc3MjU2MSwiZW52aXJvbm1lbnQiOiJTYW5kYm94IiwidHJhbnNhY3Rpb25SZWFzb24iOiJQVVJDSEFTRSIsInN0b3JlZnJvbnQiOiJKUE4iLCJzdG9yZWZyb250SWQiOiIxNDM0NjIiLCJwcmljZSI6MjMwMDAwLCJjdXJyZW5jeSI6IkpQWSJ9.vwbS3gHyL56A0b8KAeZjwIzpDfUuL8BvMWxbDSJyQcAxeLM6W6rcGVbgawSeGE0qbd6b9aXQHzy0mkBKnLeAqw'

        expected_payload = {
          'transactionId' => '2000000847061981',
          'originalTransactionId' => '2000000847061981',
          'bundleId' => 'com.goodheartapp',
          'productId' => 'gh_super_good_ticket_1',
          'purchaseDate' => 1738645560000,
          'originalPurchaseDate' => 1738645560000,
          'quantity' => 1,
          'type' => 'Consumable',
          'inAppOwnershipType' => 'PURCHASED',
          'signedDate' => 1739161772561,
          'environment' => 'Sandbox',
          'transactionReason' => 'PURCHASE',
          'storefront' => 'JPN',
          'storefrontId' => '143462',
          'price' => 230000,
          'currency' => 'JPY'
        }

        payload = AppStoreServerApi::Utils::Decoder.decode_jws!(signed_jwt)
        expect(payload).to eq expected_payload
      end
    end

  end

end
