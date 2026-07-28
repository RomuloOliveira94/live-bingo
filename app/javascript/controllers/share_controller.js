import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    url: String,
    title: String,
    text: String,
    prompt: String,
    resetDelay: { type: Number, default: 1600 }
  }

  async share(event) {
    if (event) event.preventDefault()

    if (navigator.share) {
      try {
        await navigator.share({ title: this.titleValue, text: this.textValue, url: this.urlValue })
        return
      } catch (e) {
        if (e.name === "AbortError") return
      }
    }

    await this.fallbackCopy()
  }

  async fallbackCopy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.showCopied()
    } catch (e) {
      prompt(this.promptValue, this.urlValue)
    }
  }

  showCopied() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element

    button.dataset.state = "copied"
    clearTimeout(this.resetTimeout)
    this.resetTimeout = setTimeout(() => { button.dataset.state = "idle" }, this.resetDelayValue)
  }
}
