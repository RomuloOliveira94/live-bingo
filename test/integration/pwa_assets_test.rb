require "test_helper"

class PwaAssetsTest < ActionDispatch::IntegrationTest
  test "manifest is accessible and returns valid json" do
    get "/manifest.json"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "Bingo", json["name"]
    assert_equal "Bingo", json["short_name"]
    assert_equal "#141414", json["theme_color"]
    assert_equal "#f8fafc", json["background_color"]
    assert_equal "standalone", json["display"]
    assert_equal "pt-BR", json["lang"]
    assert_equal 3, json["icons"].size
    assert json["icons"].any? { |i| i["sizes"] == "192x192" }
    assert json["icons"].any? { |i| i["sizes"] == "512x512" && i["purpose"] == "maskable" }
  end

  test "favicon ico is accessible" do
    get "/favicon.ico"
    assert_response :success
  end

  test "apple touch icon is accessible" do
    get "/apple-touch-icon.png"
    assert_response :success
  end

  test "icon 192 is accessible" do
    get "/icon-192.png"
    assert_response :success
  end

  test "icon 512 is accessible" do
    get "/icon-512.png"
    assert_response :success
  end

  test "icon svg is accessible" do
    get "/icon.svg"
    assert_response :success
  end

  test "service worker is accessible" do
    get "/service-worker.js"
    assert_response :success
  end
end
