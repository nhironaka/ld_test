# frozen_string_literal: true

require "ldclient-rb"

module DarkStore
  # Central seam for every runtime feature decision in the app.
  #
  # Each method asks LaunchDarkly for the current value, keyed off the actor
  # the call site passes in, and falls back to the constant below whenever the
  # SDK cannot answer (no SDK key configured, no connection yet, flag missing,
  # wrong value type). The fallbacks are what the app served before the SDK was
  # installed, so an unreachable LaunchDarkly is a no-op rather than an outage.
  #
  # Puma forks its workers, and a client created in the parent loses its
  # background streaming and event-flushing threads in the child, so the client
  # is built lazily and re-built whenever the pid changes. `shutdown` closes
  # the client for the current process, flushing buffered analytics events.
  class FeatureFlags
    CHECKOUT_REDESIGN = false
    BANNER_COPY = "Free shipping on orders over $50"
    MAX_CART_ITEMS = 25

    CHECKOUT_REDESIGN_KEY = "checkout-redesign"
    BANNER_COPY_KEY = "banner-copy"
    MAX_CART_ITEMS_KEY = "max-cart-items"

    DEFAULT_START_WAIT = 5

    def initialize(sdk_key: ENV.fetch("LD_SDK_KEY", nil), logger: nil, start_wait: DEFAULT_START_WAIT)
      @sdk_key = sdk_key.to_s.empty? ? nil : sdk_key
      @logger = logger
      @start_wait = start_wait
      @lock = Mutex.new
      @client = nil
      @client_pid = nil

      return if @sdk_key

      log(:warn, "No LD_SDK_KEY set; serving hardcoded flag defaults")
    end

    # Boolean rollout: gates the rebuilt checkout funnel.
    def checkout_redesign?(actor)
      variation(CHECKOUT_REDESIGN_KEY, actor, CHECKOUT_REDESIGN) == true
    end

    # String variation: marketing copy for the storefront banner.
    def banner_copy(actor)
      value = variation(BANNER_COPY_KEY, actor, BANNER_COPY)
      value.is_a?(String) ? value : BANNER_COPY
    end

    # Numeric variation: per-plan cart ceiling.
    def max_cart_items(actor)
      value = variation(MAX_CART_ITEMS_KEY, actor, MAX_CART_ITEMS)
      Integer(value)
    rescue ArgumentError, TypeError
      MAX_CART_ITEMS
    end

    # Called from the Puma `on_worker_shutdown` hook so any buffered analytics
    # get flushed before the process exits.
    def shutdown
      client = nil

      @lock.synchronize do
        client = @client if @client_pid == Process.pid
        @client = nil
        @client_pid = nil
      end

      client&.close
      nil
    end

    private

    def variation(flag_key, actor, fallback)
      client = client_for_process
      return fallback if client.nil?

      client.variation(flag_key, context_for(actor), fallback)
    rescue StandardError => e
      log(:error, "Evaluating #{flag_key} failed (#{e.class}: #{e.message}); using fallback")
      fallback
    end

    # The actor hash the call sites already build, mapped onto a single `user`
    # context. `email` is a built-in attribute; `plan` and `country` are custom
    # ones, addressable in targeting rules as-is.
    def context_for(actor)
      actor ||= {}
      attributes = {
        kind: "user",
        key: fetch(actor, :key) || "anonymous",
        plan: fetch(actor, :plan) || "free",
        country: fetch(actor, :country) || "US"
      }
      email = fetch(actor, :email)
      attributes[:email] = email if email

      LaunchDarkly::LDContext.create(attributes)
    end

    def fetch(actor, name)
      actor[name] || actor[name.to_s]
    end

    def client_for_process
      return nil if @sdk_key.nil?
      return @client if @client_pid == Process.pid

      @lock.synchronize do
        # Another thread may have won the race while this one waited.
        next if @client_pid == Process.pid

        # A client inherited across a fork is not usable and is not ours to
        # close -- the parent still owns it -- so it is simply dropped.
        @client = build_client
        @client_pid = Process.pid
      end

      @client
    end

    def build_client
      config = LaunchDarkly::Config.new(**(@logger ? { logger: @logger } : {}))
      client = LaunchDarkly::LDClient.new(@sdk_key, config, @start_wait)

      unless client.initialized?
        log(:warn, "LaunchDarkly did not connect within #{@start_wait}s; serving fallbacks until it does")
      end

      client
    rescue StandardError => e
      log(:error, "Could not start the LaunchDarkly client (#{e.class}: #{e.message}); serving hardcoded defaults")
      nil
    end

    def log(level, message)
      @logger&.public_send(level, "[launchdarkly] #{message}")
    end
  end
end
