# ruby-sinatra

Sinatra 4 storefront API. Bundler-managed, no Rails.

```sh
bundle install
bundle exec rackup      # http://localhost:9292
bundle exec puma        # http://localhost:9292, honours config/puma.rb
bundle exec rake test
```

All feature decisions live in `lib/feature_flags.rb`. Call sites are in `app.rb`.

## LaunchDarkly

`lib/feature_flags.rb` evaluates `checkout-redesign`, `banner-copy`, and
`max-cart-items` through `launchdarkly-server-sdk`, using a `user` context
built from the `X-User-*` headers the app already reads.

```sh
LD_SDK_KEY=sdk-... bundle exec puma
```

Without `LD_SDK_KEY` the app never constructs a client and every method returns
the same hardcoded constant it returned before, so tests and local runs work
offline. The same fallbacks apply if LaunchDarkly is unreachable, a flag is
missing, or a variation comes back with an unexpected type.

Puma forks its workers in cluster mode, and a client built before the fork
loses its background threads in the child, so the client is created lazily on
first evaluation in whichever process asks for it. `config/puma.rb` closes it
again on `on_worker_shutdown` / `on_stopped`, which flushes buffered analytics
events before the process exits.
