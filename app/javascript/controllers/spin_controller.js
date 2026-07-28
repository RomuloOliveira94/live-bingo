import { Controller } from "@hotwired/stimulus"

// Toggles the "spinning" cage animation (shake + fast orbit + pulse ring)
// while a draw request is in flight. The draw button's Turbo submit lifecycle
// bubbles up to this controller's element, which wraps both the button and
// the cage. When the new ball arrives (via the "last-ball" turbo-stream
// replace, or a full page render), the spinning class is naturally dropped
// since that markup never renders with it — the ballPop animation then plays
// on its own.
export default class extends Controller {
  static targets = ["cage"]

  start() {
    if (this.hasCageTarget) this.cageTarget.classList.add("is-spinning")
  }

  stop() {
    if (this.hasCageTarget) this.cageTarget.classList.remove("is-spinning")
  }
}
