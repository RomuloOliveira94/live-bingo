import { Controller } from "@hotwired/stimulus"
import { isMuted } from "sound_preference"

// Plays the draw sound the instant a ball starts spinning — see
// spin_controller.js's "bingo:spin-start" event (wired via the @window
// action on this controller's own element) and its comment for why that
// single event covers both the host (their own click) and every guest (the
// moment their browser learns a new ball is about to be revealed, before
// it's applied to the DOM). Triggering here rather than off the eventual
// DOM mutation is what makes the sound start *during* the animation instead
// of only once it settles.
//
// A guest never clicked anything, so there's no user gesture backing their
// very first sound — browsers reject that .play() call under autoplay
// policy. unlockOnFirstInteraction primes the same <audio> element on the
// guest's first tap/click/keypress anywhere on the page, so draws after that
// point play normally.
export default class extends Controller {
  connect() {
    this.audio = new Audio("/sounds/draw-sound.mp3")
    this.audio.preload = "auto"
    this.armUnlock()
  }

  disconnect() {
    this.disarmUnlock()
  }

  play() {
    // Muted: no .play() call at all — not "play then immediately pause",
    // which would still cost a real (if inaudible) playback attempt and
    // could itself interfere with the autoplay-unlock priming below (see
    // armUnlock's own comment on that exact failure mode).
    if (isMuted()) return

    this.audio.currentTime = 0
    this.audio.play().catch(() => {
      // Autoplay blocked (a guest who hasn't interacted with the page yet)
      // — a silent no-op is the correct UX, not a logged error.
    })
  }

  armUnlock() {
    this.unlock = () => {
      this.disarmUnlock()
      // For the HOST, the very first interaction with the page is often the
      // "Sortear bola" click itself — the same gesture that's about to
      // trigger a *real* play() via "bingo:spin-start". Priming here
      // synchronously would call .pause() on this shared <audio> element
      // moments later and abort that real playback. Deferring the check
      // gives the real call (if any) a moment to actually start, so this
      // only ever primes the element when nothing else is already playing.
      setTimeout(() => {
        if (!this.audio.paused) return

        this.audio.play().then(() => {
          this.audio.pause()
          this.audio.currentTime = 0
        }).catch(() => {})
      }, 100)
    }
    document.addEventListener("pointerdown", this.unlock, { once: true })
    document.addEventListener("keydown", this.unlock, { once: true })
  }

  disarmUnlock() {
    if (!this.unlock) return
    document.removeEventListener("pointerdown", this.unlock)
    document.removeEventListener("keydown", this.unlock)
    this.unlock = null
  }
}
