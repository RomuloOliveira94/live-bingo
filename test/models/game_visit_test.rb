require "test_helper"

class GameVisitTest < ActiveSupport::TestCase
  # Associations
  test "should belong to game" do
    visit = GameVisit.new(game: games(:one), visitor_token: "abc", kind: :joined, device_type: :desktop)
    assert_respond_to visit, :game
  end

  # Enums
  test "should define kind enum" do
    assert_equal %w[created joined], GameVisit.kinds.keys
  end

  test "should define device_type enum" do
    assert_equal %w[desktop mobile tablet unknown], GameVisit.device_types.keys
  end

  # Validations
  test "should be valid with valid attributes" do
    visit = GameVisit.new(game: games(:one), visitor_token: "abc", kind: :joined, device_type: :desktop)
    assert visit.valid?
  end

  test "should require visitor_token" do
    visit = GameVisit.new(game: games(:one), kind: :joined, device_type: :desktop)
    assert_not visit.valid?
    assert_includes visit.errors[:visitor_token], "não pode ficar em branco"
  end

  test "should require game" do
    visit = GameVisit.new(visitor_token: "abc", kind: :joined, device_type: :desktop)
    assert_not visit.valid?
  end

  # Dedup / unique index
  test "unique index on visitor_token + game_id rejects a duplicate insert" do
    game = games(:one)
    GameVisit.create!(game: game, visitor_token: "dup-token", kind: :created, device_type: :desktop)
    dup = GameVisit.new(game: game, visitor_token: "dup-token", kind: :joined, device_type: :desktop)

    assert_raises(ActiveRecord::RecordNotUnique) do
      dup.save(validate: false)
    end
  end

  test "the same visitor_token is allowed across two different games" do
    game_one = games(:one)
    game_two = games(:two)

    assert_difference "GameVisit.count", 2 do
      GameVisit.create!(game: game_one, visitor_token: "shared-token", kind: :joined, device_type: :desktop)
      GameVisit.create!(game: game_two, visitor_token: "shared-token", kind: :joined, device_type: :desktop)
    end
  end

  # This is the concurrency guarantee the feature actually depends on:
  # insert_all's `unique_by` compiles to a single atomic
  # `INSERT ... ON CONFLICT DO NOTHING`, so many threads racing to record the
  # same visitor+game never raise and never produce more than one row —
  # unlike an app-level "SELECT then INSERT if absent" check, which would.
  test "concurrent insert_all calls for the same visitor+game dedupe to exactly one row" do
    game = games(:one)
    visitor_token = "race-token"
    now = Time.current

    threads = 8.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GameVisit.insert_all(
            [ { game_id: game.id, visitor_token: visitor_token, kind: 1, device_type: 0, created_at: now, updated_at: now } ],
            unique_by: %i[visitor_token game_id]
          )
        end
      end
    end
    threads.each(&:join)

    assert_equal 1, GameVisit.where(game: game, visitor_token: visitor_token).count
  end
end
