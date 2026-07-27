import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "feedback"]
  static values = {
    text: String,
    feedbackTimeout: { type: Number, default: 2000 }
  }

  copy(event) {
    event.preventDefault()

    const text = this.hasTextValue ? this.textValue : this._sourceText()
    if (!text) return

    this._copyToClipboard(text).then(() => this._showFeedback())
  }

  _sourceText() {
    if (this.hasSourceTarget) {
      return this.sourceTarget.textContent.trim() ||
             this.sourceTarget.value ||
             this.sourceTarget.dataset.clipboardText || ""
    }
    return ""
  }

  _copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text)
    }

    // Fallback for older browsers / non-secure contexts
    return new Promise((resolve, reject) => {
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.setAttribute("readonly", "")
      textarea.style.position = "absolute"
      textarea.style.left = "-9999px"
      document.body.appendChild(textarea)
      textarea.select()
      try {
        document.execCommand("copy") ? resolve() : reject(new Error("copy failed"))
      } catch (err) {
        reject(err)
      } finally {
        document.body.removeChild(textarea)
      }
    })
  }

  _showFeedback() {
    if (!this.hasFeedbackTarget) return
    this.feedbackTarget.classList.remove("hidden")
    clearTimeout(this._feedbackTimer)
    this._feedbackTimer = setTimeout(() => {
      this.feedbackTarget.classList.add("hidden")
    }, this.feedbackTimeoutValue)
  }
}
