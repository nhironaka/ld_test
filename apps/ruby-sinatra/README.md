# ruby-sinatra

Sinatra 4 storefront API. Bundler-managed, no Rails.

```sh
bundle install
bundle exec rackup      # http://localhost:9292
bundle exec rake test
```

All feature decisions live in `lib/feature_flags.rb`. Call sites are in `app.rb`.
