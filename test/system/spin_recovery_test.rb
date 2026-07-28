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
end
