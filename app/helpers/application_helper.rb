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
