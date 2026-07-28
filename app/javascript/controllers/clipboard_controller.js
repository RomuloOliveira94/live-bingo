import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["feedback"]
  static values = { text: String }

  async copy(event) {
    if (event) event.preventDefault()

    try {
      await navigator.clipboard.writeText(this.textValue)
      this.showFeedback()
    } catch (e) {
      prompt("Copie:", this.textValue)
    }
  }

  showFeedback() {
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.classList.remove("hidden")
      setTimeout(() => this.feedbackTarget.classList.add("hidden"), 2000)
    }
  }
}
