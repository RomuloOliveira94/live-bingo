import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Broadcast into #redirect-slot when a game finishes (see
// GamesController#finish). Waits a moment so people can read the flash
// notice, then navigates everyone away.
export default class extends Controller {
  static values = {
    url: String,
    delay: { type: Number, default: 2500 }
  }

  connect() {
    this.timeout = setTimeout(() => Turbo.visit(this.urlValue), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
