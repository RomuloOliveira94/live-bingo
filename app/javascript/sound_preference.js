// Single source of truth for the user's draw-sound on/off preference.
//
// Persisted in localStorage — not a user account, and it must survive a
// fresh page load AND the app's full-page morph refreshes (see
// turbo_refresh_method_tag :morph in layouts/application.html.erb), which
// localStorage does for free since it isn't scoped to a single page load.
//
// Both sound_toggle_controller.js (the floating button) and
// draw_sound_controller.js (the actual playback) read/write through here
// instead of each keeping their own copy of the storage key, so the two can
// never drift out of sync with each other.
const STORAGE_KEY = "bingo:sound-muted"

export function isMuted() {
  try {
    return localStorage.getItem(STORAGE_KEY) === "1"
  } catch (e) {
    // Storage unavailable (disabled/blocked, private-mode quota) — default
    // to unmuted rather than silently losing sound with no way to fix it.
    return false
  }
}

export function setMuted(muted) {
  try {
    localStorage.setItem(STORAGE_KEY, muted ? "1" : "0")
  } catch (e) {
    // Preference just won't persist across reloads; still works in-session.
  }
}
