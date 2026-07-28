<div align="center">
  <img src="public/icon.png" width="120" alt="Live Bingo! logo — a bingo ball marked 33">

  # Live Bingo!

  **A free, real-time bingo number caller. No app, no signup, no cards — just a room and a shared code.**

  [![CI](https://github.com/RomuloOliveira94/live-bingo/actions/workflows/ci.yml/badge.svg)](https://github.com/RomuloOliveira94/live-bingo/actions/workflows/ci.yml)

  ![Ruby](https://img.shields.io/badge/Ruby-4.0.2-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
  ![Rails](https://img.shields.io/badge/Rails-8.1.3-D30001?style=for-the-badge&logo=rubyonrails&logoColor=white)
  ![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-FFE801?style=for-the-badge&logo=hotwire&logoColor=black)
  ![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)
  ![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
  ![Action Cable](https://img.shields.io/badge/Action_Cable-WebSockets-430098?style=for-the-badge)
  ![PWA](https://img.shields.io/badge/PWA-Installable-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white)

  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
</div>

## What is this?

Live Bingo! is a **sorteador** — a bingo number caller, not a full bingo game. A host opens the app, creates a room, and gets a 6-character code. Guests type that code in from any phone, tablet, or laptop — no download, no account — and watch the same draw unfold live, in sync, as the host calls numbers.

There are no personal cards and no win detection, by design. This app solves the one problem that actually needs solving at a real bingo night: making sure every player, on every device, sees the exact same number at the exact same time. The cards and the shouting are still up to you.

## Features

- **Real-time draws** — every number call is pushed to all connected guests over Turbo Streams / Action Cable; nobody needs to refresh.
- **Shared 1–75 board** — one live-updating board of every number, marking what's been drawn, identical for the host and every guest.
- **Animated ball + draw sound** — each draw spins an animated ball and plays a sound cue.
- **Installable PWA** — add it to your home screen and launch it like a native app.
- **Native share & copy-code** — share the room via the OS share sheet on mobile, or copy the code with one tap.
- **pt-BR / English** — automatic locale detection (Accept-Language, then country), no manual switch needed.
- **Privacy-conscious analytics** — visit counts for product insight, with IP addresses anonymized before they're ever stored.
- **Mobile-first** — built and tuned for a phone screen first, scales up cleanly to desktop.

## Screenshots

<table>
  <tr>
    <td align="center" width="33%"><img src="docs/screenshots/home-mobile.png" alt="Home screen on mobile — create or join a room" width="260"><br><sub>Home — create or join</sub></td>
    <td align="center" width="33%"><img src="docs/screenshots/waiting-room-mobile.png" alt="Waiting room on mobile, showing the shareable room code" width="260"><br><sub>Waiting room — share the code</sub></td>
    <td align="center" width="33%"><img src="docs/screenshots/active-game-desktop.png" alt="Live draw in progress on desktop, with the animated ball and 1-75 board" width="320"><br><sub>Live draw — desktop</sub></td>
  </tr>
</table>

## Tech stack

| Layer | Choice |
|---|---|
| Language | Ruby 4.0.2 |
| Framework | Rails 8.1.3 |
| Front end | Hotwire — Turbo Rails 2.0.23 + Stimulus Rails 1.3.4, via Importmap (**no Node/JS build step**) |
| Styling | Tailwind CSS v4 (CSS-first `@theme`, via the `tailwindcss-rails` gem) |
| Assets | Propshaft |
| Database | SQLite (every environment, including production) |
| Real-time / jobs / cache | Solid Cable, Solid Queue, Solid Cache — all SQLite-backed, no Redis |
| Testing | Minitest + Capybara/Selenium for system tests, `shoulda-matchers` for model specs |
| Deploy | Kamal + Docker (Thruster in front of Puma) |

## Getting started

```bash
git clone https://github.com/RomuloOliveira94/live-bingo.git
cd live-bingo
bin/setup      # bundle install, db:prepare, clears logs/tmp
bin/dev        # Puma + the Tailwind watcher (see Procfile.dev)
```

Then open `http://localhost:3000`.

`bin/dev` runs `Procfile.dev` via `foreman`, which starts the Rails server (`web`) and the Tailwind CSS watcher (`css`) side by side — no separate frontend toolchain to install.

## Running tests

```bash
bin/rails db:test:prepare test    # 176 runs, 893 assertions
bin/rails test:system             # 34 runs
bin/rubocop                       # style, Rails Omakase config
bin/brakeman -q                  # static security analysis
```

All four are green as of this README (0 failures, 0 offenses, 0 warnings) and run in CI on every push and pull request (see `.github/workflows/ci.yml`).

## How it works

- **No user accounts.** A host's identity is a signed, `httponly` cookie (see `SessionData`) minted the moment they create a room — nothing to sign up for, nothing to remember. The same cookie carries an anonymous per-browser visitor token used for analytics.
- **One code path for everyone.** When the host draws a ball, the response renders that draw inline for the host **and** broadcasts a Turbo Stream to every other connected guest over Action Cable — so the host isn't a special case with its own rendering logic, it's just the first person to see the update.
- **Full-page morph refresh.** State transitions (waiting → active → finished) broadcast a `broadcast_refresh_to`, which Turbo re-renders as a morphed full-page refresh rather than a targeted stream, so every guest converges on the exact same markup regardless of which screen they were on.
- **Locale resolution** checks the request's `Accept-Language` first (so an explicit Portuguese preference always wins), then falls back to the visitor's country via Cloudflare's `CF-IPCountry` header, and finally to the app default (`pt-BR`) if neither signal is present.

## Internationalization

The app is fully localized in pt-BR (default) and English, including flash messages, SEO metadata, and the PWA manifest. There's a dedicated test (`test/i18n_hardcoded_strings_test.rb`) that scans every view for un-translated literal copy and fails the build if one slips in — plus separate tests guarding locale-key parity between `pt-BR.yml`/`en.yml` and Portuguese-locale fallback behavior.

## License

This project is licensed under the [MIT License](LICENSE) — free to use, modify, and distribute, with attribution.

---

<div align="center">
  <sub>Desenvolvido com ❤️ por <a href="https://github.com/RomuloOliveira94">Rômulo Oliveira</a></sub>
</div>
