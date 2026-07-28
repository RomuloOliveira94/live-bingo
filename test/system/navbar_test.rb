require "application_system_test_case"

# Regression coverage for the context-dependent navbar (see
# layouts/_navbar.html.erb and ApplicationHelper#navbar_variant): the right
# side used to show the same create/join CTAs on every page, including the
# live game screen. It's now context-dependent — home keeps both CTAs, the
# enter page drops the redundant "Entrar" (already on the join form), and
# every game screen (waiting, active, finished — host or guest) swaps them
# for the game's own code with a copy button and a share button.
class NavbarSystemTest < ApplicationSystemTestCase
  test "home navbar shows both create and enter CTAs" do
    visit root_path

    within("header") do
      assert_selector "button", text: "Criar", exact_text: true
      assert_selector "a", text: "Entrar", exact_text: true
    end
  end

  test "enter page navbar shows only the create CTA" do
    visit enter_path

    within("header") do
      assert_selector "button", text: "Criar", exact_text: true
      assert_no_selector "a", text: "Entrar", exact_text: true
    end
  end

  test "waiting (share) screen navbar shows the game code instead of the create/join CTAs" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "#game-code", wait: 5
    code = Game.order(:created_at).last.code

    within("header") do
      assert_text code[0..2], wait: 5
      assert_no_selector "button", text: "Criar", exact_text: true
      assert_no_selector "a", text: "Entrar", exact_text: true
    end

    # The waiting screen's own in-page share block still exists further down
    # — the navbar shortcut coexists with it, it doesn't replace it.
    assert_selector "#game-code"
  end

  test "live (active) game screen navbar keeps showing the game code" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    code = Game.order(:created_at).last.code

    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    within("header") do
      assert_text code[0..2], wait: 5
    end
  end

  test "finished game screen navbar keeps showing the game code" do
    visit root_path
    click_button "Criar bingo"
    assert_selector "button", text: "Iniciar sorteio", wait: 5
    code = Game.order(:created_at).last.code

    click_button "Iniciar sorteio"
    assert_text(/ao vivo/i, wait: 5)

    accept_confirm do
      click_button "Encerrar bingo"
    end
    assert_current_path root_path, wait: 5

    visit game_path(code: code)
    assert_text "Este bingo foi encerrado.", wait: 5

    within("header") do
      assert_text code[0..2], wait: 5
    end
  end
end
