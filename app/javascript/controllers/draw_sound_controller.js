import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.audio = new Audio("/sounds/draw-sound.mp3")
    this.audio.preload = "auto"
    this.previousNumber = this.ballText()

    this.observer = new MutationObserver(() => this.handleChange())
    this.observer.observe(this.element, { childList: true, subtree: true, characterData: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  ballText() {
    return this.element.textContent.trim()
  }

  handleChange() {
    const current = this.ballText()
    if (current && current !== this.previousNumber && current !== "—") {
      this.play()
    }
    this.previousNumber = current
  }

  async play() {
    try {
      this.audio.currentTime = 0
      await this.audio.play()
    } catch (e) {
      // Autoplay blocked — user needs to interact first
    }
  }
}
