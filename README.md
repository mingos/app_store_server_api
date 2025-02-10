# AppStoreServerApi

A Ruby client for
the [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi).

[![Gem Version](https://badge.fury.io/rb/app_store_server_api.svg)](https://badge.fury.io/rb/app_store_server_api)

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
