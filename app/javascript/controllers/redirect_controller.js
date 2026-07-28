import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Broadcast into #redirect-slot when a game finishes (see
// GamesController#finish). Shows the finished notice, then waits a moment
// so people can read it before navigating everyone away.
//
// This element itself carries no visible text — only url/delay — on
// purpose: it's delivered byte-for-byte, over Action Cable, to every
// subscriber regardless of their own locale. The notice text instead comes
// from #finished-notice-template (see layouts/application.html.erb), which
// each visitor rendered themselves, in their own resolved locale, the
// moment they loaded THIS page — so showing it here never depends on
// what locale the broadcast happened to be triggered from.
export default class extends Controller {
  static values = {
    url: String,
    delay: { type: Number, default: 2500 }
  }

  connect() {
    this.showFinishedNotice()
    this.timeout = setTimeout(() => Turbo.visit(this.urlValue), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  showFinishedNotice() {
    const template = document.getElementById("finished-notice-template")
    const flash = document.getElementById("flash")
    if (!template || !flash) return

    flash.replaceChildren(template.content.cloneNode(true))
  }
}
