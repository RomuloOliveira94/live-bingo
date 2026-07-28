require "application_system_test_case"

# Regression coverage for "the spin has no terminal state except a
# successful last-ball stream" — two independent ways a draw used to leave
# the host stuck with a permanently spinning ring and a permanently
# disabled button (see spin_controller.js and GamesController#draw's
# comments for the fix):
#
#   - a genuinely dead Action Cable connection (and, before this fix, a
#     request that never even carried the reveal itself) — nothing ever
#     ends the spin. Guarded against by spin_controller.js's watchdog.
#   - an error response (stale page: game no longer active / no numbers
#     left) used to touch only the flash, never "last-ball" — the only
#     thing that ever calls endSpin — leaving the spin running forever.
#
# Also covers two watchdog/duplicate-delivery follow-up bugs found while
# empirically instrumenting a real draw (see spin_controller.js's
# matchesRingNumber and recoverFromWatchdog comments):
#
#   - the watchdog used to force-terminate onto whatever random flicker
#     number happened to be showing at that instant, leaving the host
#     staring at a ball that was never actually drawn.
#   - a duplicate "last-ball" stream (the actor gets both an inline HTTP
#     render and a broadcast copy of the same draw — see
#     GamesController#draw's comment) arriving after the first copy already
#     settled used to start a full phantom re-spin: a second draw sound and
#     a second settle animation onto a number that was already on screen.
class SpinRecoverySystemTest < ApplicationSystemTestCase
  test "a spin that never receives any stream update recovers via the watchdog" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    spin_selector = "[data-controller~='spin']"
    assert_selector spin_selector, wait: 5

    # Shrink the watchdog (still comfortably longer than a round trip
    # through Selenium/WebDriver, so the test can reliably observe the
    # "still spinning" state before it fires) so the test doesn't need to
    # wait out the real 6s default, then start a spin directly through the
    # controller — simulating a draw whose "last-ball" stream never arrives
    # at all (a dead cable AND a request that never completes), rather than
    # driving an actual draw over the network.
    page.execute_script(<<~JS)
      const el = document.querySelector(#{spin_selector.to_json})
      el.setAttribute("data-spin-watchdog-value", "2000")
      window.Stimulus.getControllerForElementAndIdentifier(el, "spin").beginSpin()
    JS

    assert_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 1

    # The watchdog (2s here) must force the spin to end even though
    # nothing else ever called endSpin.
    assert_no_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 5
    assert_selector "button", text: "Sortear bola", wait: 3
    assert_not find_button("Sortear bola").disabled?

    # No ball had ever been drawn before this simulated spin, so the
    # watchdog's recovery must leave the ring hidden again — not showing
    # whatever random number the flicker last landed on (see
    # spin_controller.js#restoreRingSnapshot). Read raw textContent/classes
    # via JS rather than Capybara's `.text`, since a `visibility: hidden`
    # element reports no text through Selenium's getText.
    ring_state = ring_state_via_js
    assert ring_state["hidden"], "the ring should return to hidden — no ball had been drawn before this spin"
    assert_equal "", ring_state["letter"]
    assert_equal "", ring_state["number"]
  end

  # Same watchdog recovery as above, but this time a real ball is already
  # showing in the ring when the dead-cable spin starts. Before the fix,
  # recoverFromWatchdog (then just endSpin) left whatever random number
  # flickerTick last wrote in place — a ball that was never actually drawn.
  test "the watchdog restores the previously drawn ball instead of a stray flicker number" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    click_button "Sortear bola"
    assert_selector "#last-ball [data-spin-target='number']", wait: 5
    assert_no_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 5

    previous = ring_state_via_js
    refute previous["hidden"], "sanity check: a real ball should already be showing"
    refute_empty previous["number"]

    spin_selector = "[data-controller~='spin']"
    page.execute_script(<<~JS)
      const el = document.querySelector(#{spin_selector.to_json})
      el.setAttribute("data-spin-watchdog-value", "2000")
      window.Stimulus.getControllerForElementAndIdentifier(el, "spin").beginSpin()
    JS

    assert_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 1
    assert_no_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 5

    restored = ring_state_via_js
    assert_equal previous["letter"], restored["letter"]
    assert_equal previous["number"], restored["number"]
    refute restored["hidden"], "a previously drawn ball must stay visible after watchdog recovery"
  end

  test "a rejected draw (stale page) still settles the spin instead of leaving it running forever" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)
    assert_selector "button", text: "Sortear bola", wait: 5

    # Simulate a stale page: the button is still visible/enabled in THIS
    # browser tab, but the game has since finished server-side (e.g. the
    # host finished it from another tab or device).
    game = Game.order(:created_at).last
    game.update!(status: :finished, finished_at: Time.current)

    click_button "Sortear bola"

    assert_text(I18n.t("draws.errors.game_not_active"), wait: 5)
    assert_no_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 5
  end

  # Regression for the phantom re-spin: the actor (host) receives the same
  # draw twice — once inline in the HTTP response, once again via
  # DrawService's broadcast (see GamesController#draw's comment). Normally
  # the second copy lands while `spinning` is still true and is absorbed for
  # free. This simulates the second copy arriving late — after the first
  # copy has already settled the spin — by injecting the exact markup
  # DrawService's broadcast would have delivered directly into the page.
  test "a duplicate last-ball stream arriving after settle does not start a phantom re-spin" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    click_button "Sortear bola"
    assert_selector "#last-ball [data-spin-target='number']", wait: 5
    assert_no_selector "#last-ball [data-spin-target='cage'].is-spinning", wait: 5

    game = Game.order(:created_at).last
    draw = game.draws.order(:position).last
    revealed_number = ring_state_via_js["number"]
    assert_equal draw.number.to_s, revealed_number

    page.execute_script(<<~JS)
      window.__spinStarts = 0
      window.addEventListener("bingo:spin-start", function () { window.__spinStarts += 1 })
    JS

    duplicate_stream_html = ApplicationController.render(
      template: "games/draw_broadcast", formats: [ :turbo_stream ],
      locals: { game: game, draw: draw }
    )
    page.execute_script(<<~JS)
      document.body.insertAdjacentHTML("beforeend", #{duplicate_stream_html.to_json})
    JS

    # Give the injected stream's connectedCallback — and, if the bug were
    # present, a full phantom spin — time to run. Comfortably past
    # minDuration (900ms default).
    sleep 1.2

    assert_equal 0, page.evaluate_script("window.__spinStarts"),
      "a duplicate of an already-settled draw must not start a second spin (no second draw sound)"
    assert_no_selector "#last-ball [data-spin-target='cage'].is-spinning"
    assert_equal revealed_number, ring_state_via_js["number"]
  end

  private

  def ring_state_via_js
    page.evaluate_script(<<~JS)
      (function() {
        var ring = document.querySelector("#last-ball [data-spin-target='ring']")
        var letter = document.querySelector("#last-ball [data-spin-target='letter']")
        var number = document.querySelector("#last-ball [data-spin-target='number']")
        return {
          hidden: ring.classList.contains("invisible"),
          letter: letter.textContent,
          number: number.textContent
        }
      })()
    JS
  end
end
