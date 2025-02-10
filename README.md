# AppStoreServerApi

A Ruby client for
the [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi).

[![Gem Version](https://badge.fury.io/rb/app_store_server_api.svg)](https://badge.fury.io/rb/app_store_server_api)

## Support API Endpoints

* [Get Transaction History](https://developer.apple.com/documentation/appstoreserverapi/get-v1-transactions)

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
# my_app/config/app_store_server_api.yml
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
client = AppStoreServerApi::Client.new(**Rails.configuration.app_store_server_api)

# change environment 
client.environment = :production # or :sandbox
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and the created tag, and push the `.gem`
file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of
the [MIT License](https://opensource.org/licenses/MIT).
