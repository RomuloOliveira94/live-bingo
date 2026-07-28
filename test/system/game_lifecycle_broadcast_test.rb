require "application_system_test_case"

# Regression test for the realtime bug QA reported: a guest connected to a
# game never saw the host's start/finish actions, because GamesController
# only broadcast_replace_to'd targets ("game-status", "last-ball") that don't
# even exist on the branch of show.html.erb a guest is rendering. The fix is
# a full morphed page refresh (see GamesController#start/#finish/#restart)
# plus, for finish specifically, an explicit "kick everyone out" broadcast.
class GameLifecycleBroadcastTest < ApplicationSystemTestCase
  test "guest sees the game start and gets kicked out with a notice when the host finishes" do
    visit root_path
    click_button "Criar bingo"

    assert_selector "#game-code", wait: 5
    code = Game.order(:created_at).last.code

    Capybara.using_session(:guest) do
      visit game_path(code: code)
      assert_text "Aguardando início do bingo"
    end

    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    Capybara.using_session(:guest) do
      # Guest must transition from the waiting screen straight to the Live
      # screen, without a manual reload, purely from the broadcasted refresh.
      assert_no_text "Aguardando início do bingo", wait: 5
      assert_text(/ao vivo/i, wait: 5)
    end

    accept_confirm do
      click_button "Encerrar bingo"
    end

    Capybara.using_session(:guest) do
      assert_text "Este bingo foi encerrado.", wait: 5
      assert_current_path root_path, wait: 6
    end

    assert_current_path root_path, wait: 5
  end
end
