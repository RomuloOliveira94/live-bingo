import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    title: String,
    text: String
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
      this.dispatch("copied", { prefix: "share" })
    } catch (e) {
      prompt("Copie o link:", this.urlValue)
    }
  }
}
