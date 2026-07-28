import { Controller } from "@hotwired/stimulus"

// GameChannel broadcasts only the raw viewer count into the "count" target
// below (see GameChannel#broadcast_viewer_count) — never the pluralized
// label. That broadcast runs in an Action Cable worker thread with no
// per-request locale, so any translated text rendered there would always
// come out at config.i18n.default_locale (pt-BR), regardless of the
// subscriber's own. Both pluralized forms of the label are rendered once,
// per visitor, in their own resolved locale (see _viewer_count.html.erb) —
// this controller only ever toggles which one is visible, reacting locally
// whenever the broadcast updates the raw count.
export default class extends Controller {
  static targets = [ "count", "labelOne", "labelOther" ]

  connect() {
    this.refresh()
    // The broadcast only replaces the count target's text content (a plain
    // Turbo Stream `update`), which fires no Stimulus lifecycle callback —
    // observe it directly rather than depend on Turbo-specific event names.
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.countTarget, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  refresh() {
    const singular = Number(this.countTarget.textContent) === 1
    if (this.hasLabelOneTarget) this.labelOneTarget.hidden = !singular
    if (this.hasLabelOtherTarget) this.labelOtherTarget.hidden = singular
  }
}
