# AppStoreServerApi

A Ruby client for
the [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi).

[![Gem Version](https://badge.fury.io/rb/app_store_server_api.svg)](https://badge.fury.io/rb/app_store_server_api)

## Support API Endpoints

* [Get Transaction Info](https://developer.apple.com/documentation/appstoreserverapi/get-v1-transactions-_transactionid_)

## Requirements

Ruby 3.0.0 or later.

## Installation

add this line to your application's Gemfile:

```Gemfile
gem 'app_store_server_api', git: 'https://github.com/mingos/app_store_server_api.git'
```

## Usage

### Prerequisites

To get started, you must obtain the following:

- An [API key](https://developer.apple.com/documentation/appstoreserverapi/creating-api-keys-to-authorize-api-requests)
- The ID of the key
- Your [issuer ID](https://developer.apple.com/documentation/appstoreserverapi/generating_tokens_for_api_requests)

### Configure

**In your Rails application, create a client configure**

```yaml
# my_app/config/app_store_server.yml
default: &default
  private_key: |
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
  key_id: Z1BT391B21
  issuer_id: ef02153z-1290-3519-875e-237a15237e3c
  bundle_id: com.myapp.app
  environment: sandbox

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

### load the configuration

```ruby
config = Rails.application.config_for(:app_store_server)
client = AppStoreServerApi::Client.new(**config)
```

## API

### Get Transaction Info

[Get Transaction Info](
https://developer.apple.com/documentation/appstoreserverapi/get-v1-transactions-_transactionid_)

Get information about a single transaction for your app.

```ruby
transaction_id = '2000000847061981'
client.get_transaction_info(transaction_id)
=>
{
  "transactionId" => "2000000847061981",
  "originalTransactionId" => "2000000847061981",
  "bundleId" => "com.myapp.app",
  "productId" => "com.myapp.app.product",
  "type" => "Consumable",
  "purchaseDate" => 1738645560000,
  "originalPurchaseDate" => 1738645560000,
  "quantity" => 1,
  ...
}
```

## License

The gem is available as open source under the terms of
the [MIT License](https://opensource.org/licenses/MIT).
