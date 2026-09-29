# BabyWorks

A small macOS app I’m building on evenings and weekends so my kid can poke at the screen without launching Spotlight, switching spaces, or otherwise “helping” with the rest of the Mac.

If you’re a young parent who’s comfortable with macOS and doesn’t mind granting Accessibility once in a while, this might be your kind of toy project too.

Made by [Camille](https://camillehdl.dev). **Every line of code in this repo was written by an AI coding agent** (human direction, agent execution).

## What it does

- **Full-screen kiosk** across your displays — calm underwater scene by default (fish, sand, bubbles), with a galaxy mode still in the codebase.
- **Keyboard shielding** during play: common shortcuts get swallowed so tiny fingers don’t escape the sandbox. Keystrokes are not logged or stored.
- **Grown-up exits**: parent passphrase + Return, Shift-Escape, or the pale failsafe corner — then the app quits and your desktop comes back.

On launch, BabyWorks tries to go straight into kid mode. You only see the French “parent tools” window if something blocked full-screen (permissions, simulated failure, etc.).

## Art credits

Underwater sprites come from **[Kenney](https://www.kenney.nl) — Fish Pack 2.0** (CC0). See `Sources/BabyWorks/Resources/Ocean/License.txt` in the repo.

## Build & run

Requirements: **macOS 13+**, **Swift 6.1** (Xcode or Swift toolchain).

```bash
swift test
swift build --product BabyWorks
.build/release/BabyWorks
```

For a signed `.app` in `/Applications` (recommended so Accessibility / TCC remembers a stable identity):

```bash
BABYWORK_CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development:.*\)".*/\1/p' | head -1)" BABYWORK_APP_SANDBOX=0 ./scripts/build-app.sh
open /Applications/BabyWorks.app
```

Open **`/Applications/BabyWorks.app`**, not a `.build` binary (the snippet above is tests/debug only). macOS keys Accessibility to the code-signing identity (CDHash). An **ad hoc** signature (`BABYWORK_CODE_SIGN_IDENTITY=-`, the script default) is debug-only: every rebuild is a new identity, so “BabyWorks” can look authorized while **Lancer session** still fails until you remove stale entries and re-grant **this** copy.

Sandbox experiment (separate bundle ID):

```bash
BABYWORK_APP_SANDBOX=1 ./scripts/build-app.sh
open /Applications/BabyWorks-sandbox.app
```

Grant **Accessibility** to BabyWorks when macOS asks — that’s what lets the app filter shortcuts during kiosk mode. If you change your mind after denying, quit and relaunch the app (or drag it into the Accessibility list from Finder).

---

Personal project, no warranty, no roadmap promises — just something that works on our family Mac.
