module ButtonsHelper
  # The 7 button variants from the design. Centralized here so every screen
  # (create/join/share/live) draws from the same set instead of re-styling
  # buttons inline.

  def btn_primary_classes
    "font-display inline-flex items-center justify-center gap-2 py-[17px] px-5 rounded-[14px] " \
    "bg-bingo-red text-bingo-on-red font-bold text-base transition hover:brightness-[.92] cursor-pointer"
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
    "border-[1.5px] border-bingo-red bg-transparent text-bingo-red font-medium text-sm " \
    "transition hover:bg-bingo-red hover:text-bingo-on-red cursor-pointer"
  end

  def btn_pill_solid_icon_classes
    "font-display inline-flex items-center justify-center gap-2 py-[11px] px-5 rounded-full " \
    "border-none bg-bingo-red text-bingo-on-red font-bold text-sm " \
    "transition hover:brightness-125 cursor-pointer"
  end

  def btn_pill_muted_classes
    "font-display inline-flex items-center justify-center py-2.5 px-4 rounded-full " \
    "border border-bingo-line bg-transparent text-bingo-muted text-[13px] " \
    "transition hover:text-bingo-red hover:border-bingo-red cursor-pointer"
  end

  def btn_draw_classes(disabled:)
    base = "font-display inline-flex items-center justify-center py-4 px-[34px] rounded-full font-bold text-base transition"
    return "#{base} bg-bingo-surface text-bingo-muted border border-bingo-line cursor-default" if disabled

    "#{base} bg-bingo-red text-bingo-on-red border-none cursor-pointer hover:brightness-[.92]"
  end
end
