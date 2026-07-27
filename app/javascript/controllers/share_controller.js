import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["feedback"]
  static values = {
    title: String,
    text: String,
    url: String,
    fallback: String,
    feedbackTimeout: { type: Number, default: 2000 }
  }

  async share(event) {
    event.preventDefault()

    const shareData = {
      title: this.titleValue || "",
      text: this.textValue || "",
      url: this.urlValue || ""
    }

    if (navigator.canShare && navigator.canShare(shareData)) {
      try {
        await navigator.share(shareData)
        return
      } catch (err) {
        // User cancelled or share failed — fall through to copy
        if (err.name === "AbortError") return
      }
    }

    // Fallback: copy URL to clipboard
    const toCopy = this.urlValue || this.fallbackValue || ""
    if (toCopy) {
      await this._copyToClipboard(toCopy)
      this._showFeedback()
    }
  }

  _copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text)
    }

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
