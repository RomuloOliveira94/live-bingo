require "application_system_test_case"

# Regression test for user feedback (with screenshot): the ring's letter+
# number pair was not optically centered — pushed up (and, for two-digit
# numbers, clipping past the ring's circular border) — because the ring used
# `items-baseline` with no compensating offset on the letter/number spans
# (see _last_ball.html.erb). align-items: baseline alone doesn't center a
# 20px/46px mismatched pair inside a fixed 104px circle; the design's own
# padding-top offsets (38px on the letter, 32px on the number) do.
#
# This measures actual rendered geometry, calibrated against the real bug:
# the broken layout put the glyph group's vertical midpoint ~50% of the
# ring's radius away from the ring's own center; the fixed layout puts it at
# a steady ~19% (an artifact of font box metrics, not literal ink, so it's
# never exactly 0% — see the measurements in git history of this file if the
# threshold ever needs revisiting). 30% cleanly separates the two.
class BallRingSystemTest < ApplicationSystemTestCase
  MAX_VERTICAL_OFFSET_RATIO = 0.30
  MAX_HORIZONTAL_OFFSET_PX = 2

  test "ring keeps a one-digit number centered" do
    assert_ring_centered(7)
  end

  test "ring keeps a two-digit number centered" do
    assert_ring_centered(42)
  end

  test "ring keeps the maximum two-digit number (75) centered" do
    assert_ring_centered(75)
  end

  private

  def assert_ring_centered(number)
    game = GameCreator.call(host_id: SessionData.host_id_for_new_game)
    game.update!(status: :active, started_at: Time.current)
    game.draws.create!(number: number, position: 1)

    visit game_path(code: game.code)
    assert_selector "#last-ball .bingo-ring", wait: 5

    geometry = page.evaluate_script(<<~JS)
      (function() {
        var ring = document.querySelector("#last-ball .bingo-ring");
        var spans = ring.querySelectorAll("span");
        var r = ring.getBoundingClientRect();
        var border = parseFloat(getComputedStyle(ring).borderTopWidth);
        var glyphs = Array.from(spans).map(function(s) {
          var b = s.getBoundingClientRect();
          return { left: b.left, right: b.right, top: b.top, bottom: b.bottom };
        });
        return {
          ring: { left: r.left, right: r.right, top: r.top, bottom: r.bottom, border: border },
          glyphs: glyphs
        };
      })()
    JS

    glyphs = geometry["glyphs"]
    refute_empty glyphs, "expected the ring to contain the letter/number spans"

    ring = geometry["ring"]
    radius = (ring["right"] - ring["left"]) / 2.0
    ring_center_x = (ring["left"] + ring["right"]) / 2.0
    ring_center_y = (ring["top"] + ring["bottom"]) / 2.0

    combined_top = glyphs.map { |g| g["top"] }.min
    combined_bottom = glyphs.map { |g| g["bottom"] }.max
    combined_left = glyphs.map { |g| g["left"] }.min
    combined_right = glyphs.map { |g| g["right"] }.max

    # Sanity check: nothing grossly overflows the ring's own square footprint
    # (a coarser guard than the centering check below — catches, e.g., the
    # ring shrinking or the font growing, independent of baseline alignment).
    content_left = ring["left"] + ring["border"]
    content_right = ring["right"] - ring["border"]
    content_top = ring["top"] + ring["border"]
    content_bottom = ring["bottom"] - ring["border"]
    assert combined_left >= content_left - 1, "letter/number overflow the ring's left edge"
    assert combined_right <= content_right + 1, "letter/number overflow the ring's right edge"
    assert combined_top >= content_top - 1, "letter/number overflow the ring's top edge"
    assert combined_bottom <= content_bottom + 1, "letter/number overflow the ring's bottom edge"

    vertical_offset = ((combined_top + combined_bottom) / 2.0) - ring_center_y
    horizontal_offset = ((combined_left + combined_right) / 2.0) - ring_center_x
    max_vertical_offset = radius * MAX_VERTICAL_OFFSET_RATIO

    assert vertical_offset.abs <= max_vertical_offset,
      "letter+number pair for #{number} is #{vertical_offset.round(1)}px off the ring's vertical " \
      "center (max allowed #{max_vertical_offset.round(1)}px) — not optically centered"
    assert horizontal_offset.abs <= MAX_HORIZONTAL_OFFSET_PX,
      "letter+number pair for #{number} is #{horizontal_offset.round(1)}px off the ring's horizontal center"
  end
end
