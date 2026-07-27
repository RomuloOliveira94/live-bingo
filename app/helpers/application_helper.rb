module ApplicationHelper
  def human_pattern(pattern)
    I18n.t("patterns.#{pattern}")
  end

  def human_game_status(status)
    I18n.t("statuses.game.#{status}")
  end

  def human_win_status(status)
    I18n.t("statuses.win.#{status}")
  end

  # Returns Tailwind classes for a card cell based on whether it's marked.
  # `cell` is either an Integer or the symbol/string :free.
  # `drawn_set` is a Set of Integers.
  def card_cell_classes(cell, drawn_set)
    drawn_set = drawn_set.is_a?(Set) ? drawn_set : drawn_set.to_set
    is_free = cell.to_s == "free"
    marked = is_free || drawn_set.include?(cell.to_i)

    base = "aspect-square flex items-center justify-center text-lg sm:text-2xl font-bold rounded transition-colors"

    if is_free
      "#{base} ring-2 ring-amber-400 bg-amber-100 text-amber-900"
    elsif marked
      "#{base} bg-emerald-200 text-emerald-900 ring-2 ring-emerald-400"
    else
      "#{base} bg-white text-slate-700"
    end
  end

  # Returns the last N drawn numbers as an array of Integers (most recent last).
  def format_drawn_numbers(draws, limit: 10)
    draws.order(:position).last(limit).map(&:number)
  end

  # Full URL for sharing a game.
  def game_url_for_sharing(game)
    "#{request.base_url}#{game_path(game.code)}"
  end

  # Short identifier for a card (last 4 chars of session_id).
  def card_short_id(card)
    sid = card.session_id.to_s
    last4 = sid.length >= 4 ? sid[-4..] : sid
    I18n.t("games.show.winners.session_short", last4: last4)
  end

  # Formatted code with letter-spacing (XXX-XXX display).
  def format_game_code(code)
    return "" if code.blank?
    "#{code[0..2]}-#{code[3..5]}"
  end
end
