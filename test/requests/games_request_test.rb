require "test_helper"

class GamesRequestTest < ActionDispatch::IntegrationTest
  test "host creates game" do
    assert_difference "Game.count", 1 do
      post games_path
    end

    assert_response :redirect
    game = Game.last
    assert_equal "waiting", game.status
    assert cookies[:bingo_session].present?

    follow_redirect!
    assert_response :success
  end

  test "show returns 200 for valid code" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    get game_path(code: game.code)
    assert_response :success
  end

  test "show 404 for invalid code" do
    get game_path(code: "INVALID")
    assert_response :not_found
  end

  test "host can start" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post start_game_path(code: game.code)
    assert_response :redirect

    game.reload
    assert_equal "active", game.status
    assert_not_nil game.started_at
  end

  test "non-host cannot start" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    post start_game_path(code: game.code)
    assert_response :not_found
  end

  test "host can draw number" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    assert_difference "Draw.count", 1 do
      post draw_game_path(code: game.code)
    end

    assert_response :redirect
    draw = Draw.last
    assert_includes 1..75, draw.number
    assert_equal 1, draw.position
  end

  test "host can draw number (turbo_stream format renders the draw's own updates inline, not a redirect)" do
    # This is what a real button_to click actually sends (Turbo adds the
    # turbo-stream mime type to the Accept header for any non-safe form
    # submission) — see GamesController#draw's comment for why a redirect
    # here broke the draw animation/sound for the host.
    #
    # It used to respond :no_content, relying entirely on DrawService's own
    # Action Cable broadcast to update the actor's own DOM — leaving the
    # actor's own spin permanently stuck whenever that broadcast never
    # arrived (dead cable). It now renders the same 5 updates inline, so the
    # actor's own click settles regardless of cable state (see
    # games/draw_broadcast.turbo_stream.erb).
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    sign_in_as_host(game)

    assert_difference "Draw.count", 1 do
      post draw_game_path(code: game.code), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type

    document = Nokogiri::HTML5.parse(response.body)
    targets = document.css("turbo-stream").map { |stream| stream["target"] }
    assert_equal %w[last-ball draw-history drawn-count board draw-button].sort, targets.sort
    assert document.css('turbo-stream[target="last-ball"]').all? { |stream| stream["action"] == "update" }
  end

  test "draw on waiting game rejected (turbo_stream format still surfaces the flash, without redirecting)" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post draw_game_path(code: game.code), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert_match I18n.t("draws.errors.game_not_active"), response.body
    assert_match(/target="flash"/, response.body)
  end

  # Regression: an error response used to only ever touch "flash" — with no
  # "last-ball" update, spin_controller.js's turbo:before-stream-render
  # listener (the only thing that ever calls endSpin) never fired, so a
  # rejected draw left the spin animation running forever with nothing to
  # reveal and the button stuck disabled.
  test "a rejected draw's turbo_stream response also updates last-ball, so the spin animation can settle" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post draw_game_path(code: game.code), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    document = Nokogiri::HTML5.parse(response.body)
    targets = document.css("turbo-stream").map { |stream| stream["target"] }
    assert_includes targets, "last-ball"
  end

  test "non-host cannot draw" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_viewer

    post draw_game_path(code: game.code)
    assert_response :not_found
  end

  test "host can restart" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    game.draws.create!(number: 1, position: 1)
    game.draws.create!(number: 2, position: 2)
    sign_in_as_host(game)

    assert_difference "Draw.count", -2 do
      post restart_game_path(code: game.code)
    end

    assert_response :redirect
  end

  test "non-host cannot restart" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_viewer

    post restart_game_path(code: game.code)
    assert_response :not_found
  end

  test "host can finish" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, viewer_count: 3)
    sign_in_as_host(game)

    post finish_game_path(code: game.code)
    assert_redirected_to root_path
    assert_equal I18n.t("games.show.finished.message"), flash[:notice]

    game.reload
    assert_equal "finished", game.status
    assert_not_nil game.finished_at
    # Abandoned/crashed subscriptions never send their decrement, so a
    # finished game resets the counter rather than carrying that drift
    # forward forever.
    assert_equal 0, game.viewer_count
  end

  test "finished host revisiting the page does not see a draw button" do
    # Regression: the draw button used to render whenever the game was
    # active OR finished, picking its disabled label from
    # `finished? || count >= 75` — so a host who finished early (say, after
    # 3 draws) and came back to the page saw a disabled "Todas as bolas
    # sorteadas" (all balls drawn) button, which is false. Finished games
    # get their own CTA (see the "Finished (host)" branch), so the draw
    # button should not render at all once the game is finished.
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :finished, finished_at: Time.current)
    game.draws.create!(number: 1, position: 1)
    sign_in_as_host(game)

    get game_path(code: game.code)

    assert_response :success
    assert_select "form[action=?]", draw_game_path(code: game.code), count: 0
    assert_select "body", text: /#{I18n.t("games.show.active.all_drawn")}/, count: 0
  end

  test "non-host cannot finish" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active)
    sign_in_as_viewer

    post finish_game_path(code: game.code)
    assert_response :not_found
  end

  test "draw on waiting game rejected" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_host(game)

    post draw_game_path(code: game.code)
    assert_response :redirect
    follow_redirect!
    assert flash[:alert].present?
  end

  # Analytics (GameVisit)
  test "creating a game records a GameVisit with kind created" do
    assert_difference "GameVisit.count", 1 do
      post games_path
    end

    visit = GameVisit.last
    assert_equal "created", visit.kind
    assert_equal Game.last.id, visit.game_id
  end

  test "showing a game records a GameVisit with kind joined" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    sign_in_as_viewer

    assert_difference "GameVisit.count", 1 do
      get game_path(code: game.code)
    end

    visit = GameVisit.last
    assert_equal "joined", visit.kind
    assert_equal game.id, visit.game_id
  end

  test "revisiting the same game as the same visitor does not duplicate the GameVisit row" do
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    cookies[:bingo_session] = { host_id: nil, visitor_token: "same-visitor" }.to_json

    get game_path(code: game.code)
    get game_path(code: game.code)

    assert_equal 1, GameVisit.where(game: game, visitor_token: "same-visitor").count
  end

  test "a fresh guest visiting the home page gets a visitor_token cookie" do
    get root_path
    assert_response :success

    assert cookies[:bingo_session].present?
    assert SessionData.cookies_to_session(cookies).visitor_token.present?
  end

  test "showing a 404 game does not record a GameVisit" do
    assert_no_difference "GameVisit.count" do
      get game_path(code: "INVALID")
    end
  end
end
