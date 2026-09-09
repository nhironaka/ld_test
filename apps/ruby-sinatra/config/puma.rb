# frozen_string_literal: true

# Puma configuration, used by `bundle exec puma`.
#
# In cluster mode Puma forks its workers, so the LaunchDarkly client is built
# lazily per process (see lib/feature_flags.rb). These hooks are the other half
# of that lifecycle: closing the client drains buffered analytics events before
# the process exits, so short-lived processes do not silently lose them.

port Integer(ENV.fetch("PORT", 9292))
workers Integer(ENV.fetch("WEB_CONCURRENCY", 0))
threads Integer(ENV.fetch("MIN_THREADS", 1)), Integer(ENV.fetch("MAX_THREADS", 5))

flush_flag_analytics = lambda do
  # The clustered parent never loads the app unless `preload_app!` is set.
  next unless defined?(DarkStore::App)

  DarkStore::App.settings.flags.shutdown
end

# Cluster mode: once per worker, as that worker exits.
on_worker_shutdown(&flush_flag_analytics)

# Single mode and the cluster parent: once, on the way out.
on_stopped(&flush_flag_analytics)
