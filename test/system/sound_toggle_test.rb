require "application_system_test_case"

# Regression coverage for the floating sound on/off toggle (see
# games/_sound_toggle.html.erb, javascript/sound_preference.js,
# javascript/controllers/{sound_toggle,draw_sound}_controller.js). Fast,
# non-browser coverage for "renders only on game screens" lives in
# test/requests/sound_toggle_request_test.rb — everything here needs a real
# browser because it's exercising localStorage, real <audio> playback, and
# actual viewport geometry.
class SoundToggleSystemTest < ApplicationSystemTestCase
  test "toggling flips aria-pressed/aria-label and persists the choice to localStorage" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "#game-code", wait: 5

    assert_selector "[data-controller='sound-toggle'][aria-pressed='false']", wait: 5
    assert_equal I18n.t("games.show.sound.mute_label"), find("[data-controller='sound-toggle']")["aria-label"]

    find("[data-controller='sound-toggle']").click

    assert_selector "[data-controller='sound-toggle'][aria-pressed='true']"
    assert_equal I18n.t("games.show.sound.unmute_label"), find("[data-controller='sound-toggle']")["aria-label"]
    assert_equal "1", page.evaluate_script("localStorage.getItem('bingo:sound-muted')")

    find("[data-controller='sound-toggle']").click

    assert_selector "[data-controller='sound-toggle'][aria-pressed='false']"
    assert_equal "0", page.evaluate_script("localStorage.getItem('bingo:sound-muted')")
  end

  test "the mute preference survives a fresh full page load" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "#game-code", wait: 5
    code = Game.order(:created_at).last.code

    find("[data-controller='sound-toggle']").click
    assert_selector "[data-controller='sound-toggle'][aria-pressed='true']"

    visit game_path(code: code)

    assert_selector "[data-controller='sound-toggle'][aria-pressed='true']", wait: 5
  end

  test "the mute preference survives a full-page morph refresh (restart broadcasts one to the host)" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    click_button "Sortear bola"
    assert_selector "#last-ball [data-spin-target='number']", wait: 5

    find("[data-controller='sound-toggle']").click
    assert_selector "[data-controller='sound-toggle'][aria-pressed='true']"

    accept_confirm do
      click_button "Reiniciar partida"
    end
    # broadcast_refresh_to's morph re-renders the whole page in place —
    # confirm the button itself survives the morph before asserting on its
    # state.
    assert_selector "button", text: "Sortear bola", wait: 5

    assert_selector "[data-controller='sound-toggle'][aria-pressed='true']", wait: 5
  end

  test "muting suppresses the draw sound's play() call entirely; unmuting restores it" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    # The active screen's own render is a fresh morph (see the "Waiting" vs
    # "Active" branches in games/show.html.erb), which reconnects
    # draw-sound and re-arms its autoplay-unlock listener (see
    # draw_sound_controller.js#armUnlock). Consume that listener with a
    # synthetic pointerdown BEFORE installing the play() spy below, so the
    # deferred priming .play() it schedules doesn't pollute the "0 calls
    # while muted" assertion further down.
    page.execute_script(<<~JS)
      document.body.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }))
    JS
    sleep 0.3 # past armUnlock's own 100ms deferral

    install_play_spy

    find("[data-controller='sound-toggle']").click
    assert_selector "[data-controller='sound-toggle'][aria-pressed='true']"

    click_button "Sortear bola"
    assert_selector "#last-ball [data-spin-target='number']", wait: 5
    assert_equal 0, page.evaluate_script("window.__playCalls || 0"),
      "muted draw must never call audio.play() at all — not play-then-mute"

    find("[data-controller='sound-toggle']").click
    assert_selector "[data-controller='sound-toggle'][aria-pressed='false']"

    click_button "Sortear bola"
    assert_selector "#last-ball [data-spin-target='number']", wait: 5
    assert page.evaluate_script("window.__playCalls || 0") > 0,
      "unmuting must restore real playback, proving mute never permanently breaks the autoplay unlock"
  end

  test "at a 390px viewport, the floating button overlaps neither the ball, the draw button, nor the history chips" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    click_button "Sortear bola"
    assert_selector "#last-ball [data-spin-target='number']", wait: 5

    page.driver.browser.manage.window.resize_to(390, 844)
    assert_selector "[data-controller='sound-toggle']", wait: 5

    rects = page.evaluate_script(<<~JS)
      (function() {
        function rect(selector) {
          var el = document.querySelector(selector)
          var r = el.getBoundingClientRect()
          return { top: r.top, left: r.left, right: r.right, bottom: r.bottom }
        }
        return {
          toggle: rect("[data-controller='sound-toggle']"),
          ball: rect("#last-ball"),
          drawButton: rect("#draw-button"),
          history: rect("#draw-history")
        }
      })()
    JS

    %w[ball drawButton history].each do |key|
      refute overlap?(rects["toggle"], rects[key]), "sound toggle overlaps ##{key} at a 390px viewport"
    end
  end

  private

  def install_play_spy
    page.execute_script(<<~JS)
      window.__playCalls = 0
      const originalPlay = HTMLMediaElement.prototype.play
      HTMLMediaElement.prototype.play = function(...args) {
        window.__playCalls += 1
        return originalPlay.apply(this, args)
      }
    JS
  end

  def overlap?(a, b)
    a["left"] < b["right"] && a["right"] > b["left"] && a["top"] < b["bottom"] && a["bottom"] > b["top"]
  end
end
