module ApplicationHelper
  # Shared horizontal container used by the navbar and every page's main
  # content, so every screen lines up on the same gutters.
  def shared_container_class
    "mx-auto w-full max-w-[980px] px-5"
  end

  def format_game_code(code)
    return "" if code.blank?
    code.to_s.scan(/.{1,3}/).first(2).join("-")
  end

  def game_url_for_sharing(game)
    "#{request.base_url}#{game_path(code: game.code)}"
  end

  def is_host_of?(game)
    Current.host_of?(game)
  end

  # Drives the navbar's context-dependent right-hand side (see
  # layouts/_navbar.html.erb): the game screens (waiting/active/finished, set
  # by GamesController#show) get the game's own code + share shortcut instead
  # of the generic create/join CTAs. Checked by controller+action rather than
  # by request path so it still applies on PagesController#join's failure
  # re-render of the :enter template (a POST, which `current_page?` would
  # never match).
  def navbar_variant
    return :game if @game
    return :enter if params[:controller] == "pages" && params[:action].in?(%w[enter join])

    :home
  end

  def bingo_letter(number)
    case number
    when 1..15  then "B"
    when 16..30 then "I"
    when 31..45 then "N"
    when 46..60 then "G"
    when 61..75 then "O"
    end
  end
end
