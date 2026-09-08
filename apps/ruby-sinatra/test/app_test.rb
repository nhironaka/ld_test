# frozen_string_literal: true

require "minitest/autorun"
require "rack/test"

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    DarkStore::App
  end

  def test_health
    get "/health"
    assert_equal 200, last_response.status
  end

  def test_storefront_serves_a_banner_and_checkout_variant
    get "/api/storefront", {}, { "HTTP_X_USER_KEY" => "user-1" }
    body = JSON.parse(last_response.body)

    assert_equal 200, last_response.status
    refute_empty body.fetch("banner")
    assert_includes %w[legacy redesign], body.fetch("checkout")
  end

  def test_cart_rejects_quantities_over_the_limit
    post "/api/cart/items",
         JSON.generate(quantity: 10_000),
         { "CONTENT_TYPE" => "application/json" }

    assert_equal 422, last_response.status
    assert_equal "cart_limit_exceeded", JSON.parse(last_response.body).fetch("error")
  end

  def test_cart_accepts_quantities_within_the_limit
    post "/api/cart/items",
         JSON.generate(quantity: 2),
         { "CONTENT_TYPE" => "application/json" }

    assert_equal 201, last_response.status
    assert_equal 2, JSON.parse(last_response.body).fetch("quantity")
  end
end
