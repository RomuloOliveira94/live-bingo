import { Controller } from "@hotwired/stimulus"
import { isMuted, setMuted } from "sound_preference"

// Floating mute/unmute button for the draw sound (see
// draw_sound_controller.js, which reads the same isMuted() at play() time —
// this controller only ever writes the preference and reflects it visually,
// it never talks to draw-sound directly). Available to host and guest alike
// on every game screen.
//
// The element itself is a real <button> (not a div) so aria-pressed and a
// native click/keyboard interaction come for free. Labels come in as values
// (rendered server-side via t(...), see games/show.html.erb) rather than
// being hardcoded here, matching share_controller.js/clipboard_controller.js's
// existing pattern of keeping user-facing copy out of JS entirely.
export default class extends Controller {
  static values = {
    muteLabel: String,
    unmuteLabel: String
  }

  // Runs on every real connect — first render of a game page, or a fresh
  // navigation to one — so the button reflects whatever localStorage
  // currently holds rather than whatever it happened to render as
  // server-side (the server has no idea of this preference at all; it's
  // 100% client-side).
  //
  // Deliberately does NOT need to run again after a same-page morph refresh
  // (see turbo_refresh_method_tag :morph, and broadcast_refresh_to in
  // GamesController): the button carries data-turbo-permanent (see
  // games/_sound_toggle.html.erb), so Turbo skips it entirely on morph and
  // this element/controller instance — and whatever render() last set on
  // it — survives untouched. That's not just an optimization; a morph that
  // WASN'T skipped would patch aria-pressed/data-state back to the
  // server's hardcoded "unmuted" default in place, and Stimulus only
  // reconnects elements that are actually added/removed from the DOM, so a
  // plain in-place attribute patch would never trigger this connect() again
  // to fix it back up.
  connect() {
    this.render(isMuted())
  }

  toggle() {
    const muted = !isMuted()
    setMuted(muted)
    this.render(muted)
  }

  render(muted) {
    this.element.dataset.state = muted ? "muted" : "unmuted"
    this.element.setAttribute("aria-pressed", muted ? "true" : "false")
    this.element.setAttribute("aria-label", muted ? this.unmuteLabelValue : this.muteLabelValue)
  }
}
