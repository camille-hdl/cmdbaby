# CmdBaby

[![CI](https://github.com/camille-hdl/cmdbaby/actions/workflows/ci.yml/badge.svg)](https://github.com/camille-hdl/cmdbaby/actions/workflows/ci.yml)

A small macOS app I’m building on evenings and weekends so my kid can poke at the screen without launching Spotlight, switching spaces, or otherwise “helping” with the rest of the Mac.

If you’re a young parent who’s comfortable with macOS and doesn’t mind granting Accessibility once in a while, this might be your kind of toy project too.

Made by [Camille](https://camillehdl.dev). **Every line of code in this repo was written by an AI coding agent** (human direction, agent execution).

## What it does

- **Full-screen kiosk** across your displays — calm underwater scene by default (fish, sand, bubbles), plus a green-rain terminal and a spaceship that zaps whatever key your kid presses.
- **Keyboard shielding** during play: common shortcuts get swallowed so tiny fingers don’t escape the sandbox. Keystrokes are not logged or stored.
- **Grown-up exits**: configurable in Settings. The exit passphrase defaults to `parent` (then Return), alongside holding Shift-Escape for 1.5 s and the pale failsafe corner. A session timer defaults to 20 minutes. Any of these quits the app and brings the desktop back.

On launch, CmdBaby tries to go straight into kid mode. You only see the French “parent tools” window if something blocked full-screen (permissions, simulated failure, etc.).

## Art credits

Underwater sprites come from **[Kenney](https://www.kenney.nl) — Fish Pack 2.0** (CC0). See `Sources/CmdBaby/Resources/Ocean/License.txt` in the repo.

Space sprites and skyboxes come from **[Kenney](https://www.kenney.nl) — Space Shooter Remastered, Alien UFO Pack and Skyboxes Space** (CC0). See `Sources/CmdBaby/Resources/Starship/License-Starship.txt`.

## Build & run

Requirements: **macOS 13+**, **Swift 6.1** (Xcode or Swift toolchain).

```bash
swift test
swift build --product CmdBaby
.build/release/CmdBaby
```

For a signed `.app` in `/Applications` (recommended so Accessibility / TCC remembers a stable identity):

```bash
CMDBABY_CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development:.*\)".*/\1/p' | head -1)" CMDBABY_APP_SANDBOX=0 ./scripts/build-app.sh
open /Applications/CmdBaby.app
```

Open **`/Applications/CmdBaby.app`**, not a `.build` binary (the snippet above is tests/debug only). macOS keys Accessibility to the code-signing identity (CDHash). An **ad hoc** signature (`CMDBABY_CODE_SIGN_IDENTITY=-`, the script default) is debug-only: every rebuild is a new identity, so “CmdBaby” can look authorized while **Lancer session** still fails until you remove stale entries and re-grant **this** copy.

Sandbox experiment (separate bundle ID):

```bash
CMDBABY_APP_SANDBOX=1 ./scripts/build-app.sh
open /Applications/CmdBaby-sandbox.app
```

Grant **Accessibility** to CmdBaby when macOS asks — that’s what lets the app filter shortcuts during kiosk mode. If you change your mind after denying, quit and relaunch the app (or drag it into the Accessibility list from Finder).

---

Personal project, no warranty, no roadmap promises — just something that works on our family Mac.

### Git hooks

Once per clone, enable the versioned pre-commit hook, which refuses keys, certificates and release artifacts:

```bash
git config core.hooksPath scripts/git-hooks
```

## Security

See [SECURITY.md](SECURITY.md) to report a vulnerability, and [how to verify a download](docs/securite.md#6-vérifier-un-téléchargement) (in French).

## Website

The site for https://cmdbaby.app lives in `site/` and is served by Cloudflare Workers. First-time setup (Wrangler login, domain, DNS, email, security): `scripts/setup-site.sh`. Later deploys: `scripts/deploy-site.sh`. Local preview: `npm run --prefix site dev` (Tailwind build, then `wrangler dev`). Settings screenshots: `scripts/site-screenshots.sh`.
