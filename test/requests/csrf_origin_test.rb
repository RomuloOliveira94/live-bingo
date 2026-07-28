require "test_helper"

# Regression coverage for a production 422: CapRover's nginx terminates TLS
# and reverse-proxies plain HTTP to the container, so without
# `config.assume_ssl` Rails computed `request.base_url` as "http://...",
# which never matched the browser's "https://" Origin header — every
# non-GET request (including creating a game) was rejected by CSRF's
# same-origin check before it ever reached the controller (see
# ActionController::RequestForgeryProtection#valid_request_origin?, which
# compares `request.origin == request.base_url`).
#
# config/environments/test.rb turns forgery protection off entirely
# (`allow_forgery_protection = false`), which is why every other request
# test in this suite posts without a token — so this file switches it back
# on for its own examples to actually exercise the check that broke in
# production, and fetches a real token via a GET the same way a browser
# would (through the csrf-token meta tag), rather than reaching into Rails
# internals to fabricate one.
class CsrfOriginTest < ActionDispatch::IntegrationTest
  setup do
    ActionController::Base.allow_forgery_protection = true
    get root_path
    @authenticity_token = Nokogiri::HTML5.parse(response.body).at_css('meta[name="csrf-token"]')["content"]
  end

  teardown do
    ActionController::Base.allow_forgery_protection = false
  end

  test "a request the app doesn't know is HTTPS rejects a matching https:// Origin (the bug, reproduced)" do
    post games_path,
      params: { authenticity_token: @authenticity_token },
      headers: { "Origin" => "https://www.example.com" }

    assert_response :unprocessable_entity
  end

  # `https!` puts the exact same signal on the request that
  # ActionDispatch::AssumeSSL (config.assume_ssl, enabled in
  # config/environments/production.rb for exactly this reverse-proxy setup)
  # forces onto every request behind the proxy: HTTPS "on" and
  # rack.url_scheme "https" — all `request.base_url` needs to resolve to
  # "https://..." and match the Origin header.
  test "once the app knows the request is HTTPS, a matching https:// Origin is accepted (the fix)" do
    https!

    post games_path,
      params: { authenticity_token: @authenticity_token },
      headers: { "Origin" => "https://www.example.com" }

    assert_response :redirect
  end

  # Belt-and-suspenders lock on the actual production setting: the tests
  # above only pin the general Rails mechanism (they'd keep passing even if
  # `config.assume_ssl`/`config.force_ssl` were reverted, since `https!`
  # sets the env directly). This guards the config file itself so a future
  # "clean up production.rb" pass can't silently re-comment the fix.
  test "production enables assume_ssl and force_ssl for the CapRover reverse proxy" do
    production_config = File.read(Rails.root.join("config/environments/production.rb"))

    assert_match(/^\s*config\.assume_ssl\s*=\s*true/, production_config)
    assert_match(/^\s*config\.force_ssl\s*=\s*true/, production_config)
  end
end
