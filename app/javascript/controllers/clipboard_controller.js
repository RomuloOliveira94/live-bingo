import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    text: String,
    prompt: String,
    resetDelay: { type: Number, default: 1600 }
  }

  async copy(event) {
    if (event) event.preventDefault()

    try {
      await navigator.clipboard.writeText(this.textValue)
      this.showCopied()
    } catch (e) {
      prompt(this.promptValue, this.textValue)
    }
  }

  showCopied() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element

    button.dataset.state = "copied"
    clearTimeout(this.resetTimeout)
    this.resetTimeout = setTimeout(() => { button.dataset.state = "idle" }, this.resetDelayValue)
  }
}
