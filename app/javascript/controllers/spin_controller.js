import { Controller } from "@hotwired/stimulus"

// Drives the "drawing a ball" suspense animation: shake + fast orbit + pulse
// ring while a draw is in flight, flickering random numbers in the ring,
// then settling on the real drawn number with a pop.
//
// GamesController#draw no longer does a full-page redirect (see its
// comment), so both the host and every guest receive the new ball the same
// way: a "last-ball" Turbo Stream update over the game's existing
// turbo_stream_from subscription. That gives two entry points into the same
// spin:
//
//   - the host's own click starts it immediately, via turbo:submit-start on
//     the wrapping element (see show.html.erb) — instant feedback before the
//     network round trip even begins.
//   - turbo:before-stream-render fires for *every* subscriber (host and
//     guest alike) the instant the "last-ball" stream arrives over Action
//     Cable, before it's applied to the DOM. Intercepting it lets a guest
//     (who never clicked anything) start the same spin, and lets us hold the
//     real content back for a minimum duration so the flicker is actually
//     perceptible instead of an instant swap.
//
// The revealed number always comes from the server's own broadcast — the
// flicker is purely decorative.
//
// Two things guarantee this spin always reaches a terminal state even when
// the "last-ball" stream above never arrives:
//
//   - GamesController#draw renders its own turbo_stream response inline for
//     the actor (in addition to broadcasting to everyone else), so the
//     draw's own click no longer depends on a live Action Cable connection
//     at all — see its comment. Error responses (game not active / no
//     numbers left) include a "last-ball" update too, purely so this
//     controller's own interception logic settles the spin instead of
//     leaving it running with nothing to reveal.
//   - watchdogValue below is the last-resort net for the truly dead-cable-
//     AND-dead-request case: if nothing has ended the spin within that
//     window, force it.
export default class extends Controller {
  static targets = [ "cage", "ring", "letter", "number", "button" ]
  static values = {
    minDuration: { type: Number, default: 900 },
    flickerInterval: { type: Number, default: 70 },
    watchdog: { type: Number, default: 6000 }
  }

  connect() {
    this.spinning = false
    this.startedAt = 0
    this.flickerTimer = null
    this.watchdogTimer = null
    this.beforeStreamRenderListener = this.holdBeforeStreamRender.bind(this)
    document.addEventListener("turbo:before-stream-render", this.beforeStreamRenderListener)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.beforeStreamRenderListener)
    this.stopFlicker()
    this.disarmWatchdog()
  }

  // Host click — bound to turbo:submit-start on the wrapping element.
  start() {
    this.beginSpin()
  }

  // The draw button is broadcast-updated independently of the ball (see
  // DrawService#broadcast_draw / _draw_button.html.erb), purely reflecting
  // server-side "have all 75 been drawn?" truth — it has no idea a spin is
  // still in progress client-side, and usually lands *during* the hold below
  // (it isn't held back the way "last-ball" is). Without this, that
  // broadcast would swap in a fresh, server-rendered (and therefore
  // re-enabled) button mid-spin, reopening the double-submit window this
  // controller is trying to close. Stimulus calls this automatically
  // whenever an element matching the "button" target connects — including
  // right after that swap — so re-assert the disabled state if we're still
  // spinning.
  buttonTargetConnected(element) {
    if (this.spinning) element.disabled = true
  }

  // turbo:submit-end fires once the HTTP response settles (almost
  // immediately, since the controller now responds with :no_content) — well
  // before the held reveal below applies. Turbo re-enables the submit button
  // as part of that same lifecycle; keep it disabled a little longer so a
  // second click can't fire mid-spin.
  stop() {
    if (this.spinning && this.hasButtonTarget) this.buttonTarget.disabled = true
  }

  holdBeforeStreamRender(event) {
    const stream = event.target
    if (stream.target !== "last-ball") return

    this.beginSpin()

    const elapsed = Date.now() - this.startedAt
    const remaining = Math.max(0, this.minDurationValue - elapsed)
    const originalRender = event.detail.render

    event.detail.render = (streamElement) => new Promise((resolve) => {
      setTimeout(async () => {
        // Stop flickering *before* the real content lands, so a straggling
        // flicker tick can't overwrite the true number that's about to show.
        this.endSpin()
        await originalRender(streamElement)
        resolve()
      }, remaining)
    })
  }

  beginSpin() {
    if (this.spinning) return

    this.spinning = true
    this.startedAt = Date.now()
    if (this.hasCageTarget) this.cageTarget.classList.add("is-spinning")
    if (this.hasRingTarget) this.ringTarget.classList.remove("invisible")
    if (this.hasButtonTarget) this.buttonTarget.disabled = true
    this.startFlicker()
    this.armWatchdog()
    window.dispatchEvent(new CustomEvent("bingo:spin-start"))
  }

  // Re-enables the button unless the CURRENT button target — which may
  // have been swapped mid-spin by the draw-button broadcast (see
  // buttonTargetConnected) — is already marking the game as fully drawn.
  // Without this check, this line unconditionally clobbered that
  // broadcast's server-rendered `disabled` attribute the instant the spin
  // settled, leaving a clickable-but-mislabeled button after ball 75 (see
  // _draw_button.html.erb for the data-spin-all-drawn marker itself).
  endSpin() {
    this.disarmWatchdog()
    this.spinning = false
    this.stopFlicker()
    if (this.hasCageTarget) this.cageTarget.classList.remove("is-spinning")
    if (this.hasButtonTarget && this.buttonTarget.dataset.spinAllDrawn !== "true") {
      this.buttonTarget.disabled = false
    }
  }

  // Last-resort recovery for a spin that never reaches a "last-ball" stream
  // at all — a dead Action Cable connection AND a request that never comes
  // back (hung, dropped mid-flight). Cleared by endSpin whenever the spin
  // does end normally, so this never fires on the happy path.
  armWatchdog() {
    this.disarmWatchdog()
    this.watchdogTimer = setTimeout(() => this.endSpin(), this.watchdogValue)
  }

  disarmWatchdog() {
    if (this.watchdogTimer) clearTimeout(this.watchdogTimer)
    this.watchdogTimer = null
  }

  startFlicker() {
    this.stopFlicker()
    this.flickerTimer = setInterval(() => this.flickerTick(), this.flickerIntervalValue)
  }

  stopFlicker() {
    if (this.flickerTimer) clearInterval(this.flickerTimer)
    this.flickerTimer = null
  }

  flickerTick() {
    if (!this.hasLetterTarget || !this.hasNumberTarget) return

    const number = 1 + Math.floor(Math.random() * 75)
    this.numberTarget.textContent = number
    this.letterTarget.textContent = this.letterFor(number)
  }

  letterFor(number) {
    if (number <= 15) return "B"
    if (number <= 30) return "I"
    if (number <= 45) return "N"
    if (number <= 60) return "G"
    return "O"
  }
}
