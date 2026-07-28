import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

// Subscribes to GameChannel so viewer presence (Game#viewer_count) actually
// gets tracked. Reuses Turbo's own Action Cable consumer — no separate
// @rails/actioncable import needed. GameChannel itself increments/decrements
// the count on subscribe/unsubscribe and broadcasts the update.
export default class extends Controller {
  static values = { code: String }

  connect() {
    this.subscription = cable.subscribeTo({ channel: "GameChannel", code: this.codeValue })
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }
}
