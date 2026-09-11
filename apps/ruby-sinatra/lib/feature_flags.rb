# frozen_string_literal: true

module DarkStore
  # Central seam for every runtime feature decision in the app.
  #
  # Today these are hardcoded compile-time constants. The intent is for each
  # method to consult a remote flag evaluation service, keyed off the current
  # request's user, so we can roll changes out gradually instead of shipping a
  # deploy per toggle.
  #
  # Every call site already passes an `actor` hash, so whatever we swap in has
  # the identifying attributes it needs.
  class FeatureFlags
    CHECKOUT_REDESIGN = false
    BANNER_COPY = "Free shipping on orders over $50"
    MAX_CART_ITEMS = 25

    def initialize(sdk_key: ENV.fetch("LD_SDK_KEY", nil), logger: nil)
      @sdk_key = sdk_key
      @logger = logger
    end

    # Boolean rollout: gates the rebuilt checkout funnel.
    def checkout_redesign?(actor)
      _ = actor
      CHECKOUT_REDESIGN
    end

    # String variation: marketing copy for the storefront banner.
    def banner_copy(actor)
      _ = actor
      BANNER_COPY
    end

    # Numeric variation: per-plan cart ceiling.
    def max_cart_items(actor)
      _ = actor
      MAX_CART_ITEMS
    end

    # Called from the Puma `on_worker_shutdown` hook so any buffered analytics
    # get flushed before the process exits.
    def shutdown
      nil
    end
  end
end
