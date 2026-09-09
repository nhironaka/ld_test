# frozen_string_literal: true

require "json"
require "logger"
require "sinatra/base"

require_relative "lib/feature_flags"

module DarkStore
  # A deliberately small storefront API. Three endpoints, each of which makes
  # exactly one feature decision.
  class App < Sinatra::Base
    set :host_authorization, permitted_hosts: []
    set :show_exceptions, false

    configure do
      # The flag client logs its own connection state, so give it somewhere
      # to go rather than swallowing it.
      set :flags, FeatureFlags.new(logger: Logger.new($stderr))
    end

    helpers do
      # The authenticated caller, reduced to the attributes a targeting rule
      # would plausibly want.
      def actor
        {
          key: request.env.fetch("HTTP_X_USER_KEY", "anonymous"),
          email: request.env["HTTP_X_USER_EMAIL"],
          plan: request.env.fetch("HTTP_X_USER_PLAN", "free"),
          country: request.env.fetch("HTTP_X_USER_COUNTRY", "US")
        }
      end

      def flags
        settings.flags
      end

      def json(payload)
        content_type :json
        JSON.generate(payload)
      end
    end

    get "/health" do
      json(status: "ok")
    end

    get "/api/storefront" do
      json(
        banner: flags.banner_copy(actor),
        checkout: flags.checkout_redesign?(actor) ? "redesign" : "legacy"
      )
    end

    post "/api/cart/items" do
      # Rack may already have consumed the stream while building `params`.
      request.body.rewind
      body = request.body.read
      payload = body.empty? ? {} : JSON.parse(body)
      requested = Integer(payload.fetch("quantity", 1))
      ceiling = flags.max_cart_items(actor)

      if requested > ceiling
        status 422
        json(error: "cart_limit_exceeded", limit: ceiling)
      else
        status 201
        json(quantity: requested, limit: ceiling)
      end
    end

    error JSON::ParserError, ArgumentError do
      status 400
      json(error: "invalid_request")
    end

    run! if app_file == $PROGRAM_NAME
  end
end
