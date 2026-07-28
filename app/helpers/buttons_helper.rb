module ButtonsHelper
  # The 7 button variants from the design. Centralized here so every screen
  # (create/join/share/live) draws from the same set instead of re-styling
  # buttons inline.

  def btn_primary_classes
    "font-display inline-flex items-center justify-center gap-2 py-[17px] px-5 rounded-[14px] " \
    "bg-bingo-accent text-bingo-on-accent font-bold text-base transition hover:brightness-[.92] cursor-pointer"
  end

  def btn_secondary_outline_classes
    "font-display inline-flex items-center justify-center gap-2 py-[17px] px-5 rounded-[14px] " \
    "border-[1.5px] border-bingo-line bg-transparent text-bingo-fg font-medium text-base " \
    "transition hover:border-bingo-fg cursor-pointer"
  end

  def btn_ghost_classes
    "font-display inline-flex items-center justify-center py-3 px-3 bg-transparent " \
    "text-bingo-muted text-sm transition hover:text-bingo-fg cursor-pointer"
  end

  def btn_pill_outline_classes
    "font-display inline-flex items-center justify-center py-[11px] px-5 rounded-full " \
    "border-[1.5px] border-bingo-accent bg-transparent text-bingo-accent font-medium text-sm " \
    "transition hover:bg-bingo-accent hover:text-bingo-on-accent cursor-pointer"
  end

  def btn_pill_solid_icon_classes
    "font-display inline-flex items-center justify-center gap-2 py-[11px] px-5 rounded-full " \
    "border-none bg-bingo-accent text-bingo-on-accent font-bold text-sm " \
    "transition hover:brightness-125 cursor-pointer"
  end

  def btn_pill_muted_classes
    "font-display inline-flex items-center justify-center py-2.5 px-4 rounded-full " \
    "border border-bingo-line bg-transparent text-bingo-muted text-[13px] " \
    "transition hover:text-bingo-accent hover:border-bingo-accent cursor-pointer"
  end

  def btn_draw_classes(disabled:)
    base = "font-display inline-flex items-center justify-center py-4 px-[34px] rounded-full font-bold text-base transition"
    return "#{base} bg-bingo-surface text-bingo-muted border border-bingo-line cursor-default" if disabled

    "#{base} bg-bingo-accent text-bingo-on-accent border-none cursor-pointer hover:brightness-[.92]"
  end

  # Compact pair used in the navbar (every page, including the live game
  # screen) — small enough to fit the header row without growing it past the
  # logo's own height.
  def btn_nav_primary_classes
    "font-display inline-flex items-center justify-center py-1.5 px-3.5 rounded-full " \
    "bg-bingo-accent text-bingo-on-accent font-bold text-xs transition hover:brightness-[.92] cursor-pointer"
  end

  def btn_nav_secondary_classes
    "font-display inline-flex items-center justify-center py-1.5 px-3.5 rounded-full " \
    "border-[1.5px] border-bingo-line bg-transparent text-bingo-fg font-medium text-xs " \
    "transition hover:border-bingo-fg cursor-pointer"
  end
end
