require "application_system_test_case"

# Regression test for the "draw button re-enables itself after ball 75" bug
# (deterministic on every completed game): spin_controller.js#endSpin used
# to unconditionally set buttonTarget.disabled = false the instant the spin
# animation settled, clobbering the disabled "all drawn" button that the
# final draw's own draw-button broadcast had just delivered — see
# _draw_button.html.erb's data-spin-all-drawn marker and
# spin_controller.js#endSpin for the fix.
class DrawAll75SystemTest < ApplicationSystemTestCase
  test "the draw button stays disabled after the 75th ball, once the spin settles" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "#game-code", wait: 5

    game = Game.order(:created_at).last
    game.update!(status: :active, started_at: Time.current)
    # Seed 74 of the 75 numbers directly (bypassing DrawService — no need
    # for its broadcast here), leaving exactly one remaining so the click
    # below deterministically draws ball 75.
    (1..74).each_with_index { |number, index| game.draws.create!(number: number, position: index + 1) }

    visit game_path(code: game.code)
    assert_text(/74\s*\/\s*75/, wait: 5)
    assert_selector "button", text: "Sortear bola", wait: 5

    click_button "Sortear bola"

    # Wait for the spin's suspense animation to fully settle on the final
    # ball — the bug only reproduced once endSpin ran, not while spinning.
    assert_text(/75\s*\/\s*75/, wait: 5)
    assert_selector "button[disabled]", text: I18n.t("games.show.active.all_drawn"), wait: 5

    # Give any lingering broadcast/JS a moment — the button must still be
    # disabled a beat after the spin settles, not just in the instant the
    # ball lands.
    sleep 1
    assert_selector "button[disabled]", text: I18n.t("games.show.active.all_drawn")
  end
end
