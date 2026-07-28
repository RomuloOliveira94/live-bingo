require "application_system_test_case"

# Regression test for user feedback: the draw animation and draw sound never
# ran for the host. Root cause — confirmed by instrumenting the browser, not
# assumed: GamesController#draw used to redirect_to game_path after every
# draw, so the HOST's own browser did a full Turbo Drive visit on every draw
# (see "turbo:visit" below — that event only fires for an actual page visit,
# never for a Turbo Stream broadcast). That visit tore down the in-flight
# spin animation and pre-empted the draw sound before either could run (see
# spin_controller.js / draw_sound_controller.js). Guests, who only ever
# received DrawService's broadcast and never navigated, were unaffected —
# this test specifically exercises the host's own click, since that's the
# path that was broken.
class DrawNoReloadSystemTest < ApplicationSystemTestCase
  test "the host's own draw click updates the DOM via broadcast, without a full-page Turbo visit" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5

    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    # GamesController#start still redirects (out of scope here — no
    # animation to protect on that transition), and the host's own browser
    # settles that redirect's Turbo visit asynchronously, sometimes a moment
    # after the page already reads "ao vivo" via the faster broadcast_refresh.
    # Let it fully land before arming the listener below, or it gets
    # mistaken for a visit triggered by the draw click itself.
    sleep 1

    page.execute_script(<<~JS)
      window.__turboVisits = 0
      document.addEventListener("turbo:visit", function () { window.__turboVisits += 1 })
    JS

    click_button "Sortear bola"

    # Proves the broadcast actually landed (not just that nothing happened —
    # a passing assertion count of zero visits would be meaningless if the
    # ball never updated at all).
    assert_selector "#last-ball .bingo-ring", wait: 5

    # The broadcast-driven reveal above lands almost immediately either way
    # (DrawService broadcasts regardless of what the controller does after).
    # What actually distinguishes the bug is a *redirect*-driven Turbo visit,
    # which — on the old code — followed asynchronously, roughly a second or
    # so after the click. Give one enough time to show up if it were going to.
    sleep 1.5

    assert_equal 0, page.evaluate_script("window.__turboVisits"),
      "drawing triggered a full Turbo Drive visit — the host's own click " \
      "should update the DOM purely via the game's existing turbo_stream broadcast"
  end
end
