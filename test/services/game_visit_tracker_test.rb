require "test_helper"

class GameVisitTrackerTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:headers, :remote_ip, :user_agent)

  test "records a visit with all fields derived from the request" do
    game = games(:one)
    request = fake_request(
      headers: { "CF-IPCountry" => "BR" },
      remote_ip: "203.0.113.77",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    )

    assert_difference "GameVisit.count", 1 do
      GameVisitTracker.call(game: game, request: request, visitor_token: "visitor-1", kind: :created)
    end

    visit = GameVisit.last
    assert_equal game.id, visit.game_id
    assert_equal "visitor-1", visit.visitor_token
    assert visit.created?
    assert_equal "203.0.113.0", visit.ip_address
    assert_equal "Chrome", visit.browser
    assert_equal "Windows", visit.os
    assert visit.desktop?
    assert_equal "BR", visit.country_code
    assert_equal I18n.locale.to_s, visit.locale
  end

  test "truncates spoofable geo headers before storing them, like user_agent already is" do
    game = games(:one)
    request = fake_request(
      headers: {
        "CF-IPCountry" => "B" * 20,
        "CF-Region" => "R" * 300,
        "CF-IPCity" => "C" * 300
      }
    )

    GameVisitTracker.call(game: game, request: request, visitor_token: "visitor-truncate", kind: :created)

    visit = GameVisit.last
    assert_equal 10, visit.country_code.length
    assert_equal 255, visit.region.length
    assert_equal 255, visit.city.length
  end

  test "does not create a duplicate row for the same visitor and game" do
    game = games(:one)
    request = fake_request

    GameVisitTracker.call(game: game, request: request, visitor_token: "visitor-2", kind: :created)
    GameVisitTracker.call(game: game, request: request, visitor_token: "visitor-2", kind: :joined)

    matches = GameVisit.where(game: game, visitor_token: "visitor-2")
    assert_equal 1, matches.count
    # The first (winning) insert's kind is preserved — the second insert is a
    # no-op, not an overwrite.
    assert_equal "created", matches.first.kind
  end

  test "does nothing when visitor_token is blank (e.g. cookies disabled)" do
    game = games(:one)
    request = fake_request

    assert_no_difference "GameVisit.count" do
      GameVisitTracker.call(game: game, request: request, visitor_token: nil, kind: :joined)
      GameVisitTracker.call(game: game, request: request, visitor_token: "", kind: :joined)
    end
  end

  test "rescues an internal failure instead of raising into the request" do
    request = fake_request

    result = nil
    assert_nothing_raised do
      # A nil game is an easy, dependency-free way to force a genuine
      # internal failure (@game.id raises NoMethodError) and prove the
      # rescue swallows it rather than special-casing nil elsewhere.
      result = GameVisitTracker.call(game: nil, request: request, visitor_token: "visitor-3", kind: :created)
    end

    assert_nil result
    assert_equal 0, GameVisit.count
  end

  private

  def fake_request(headers: {}, remote_ip: "198.51.100.7", user_agent: "TestAgent/1.0")
    FakeRequest.new(headers, remote_ip, user_agent)
  end
end
