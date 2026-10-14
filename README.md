<h1 align="center">dotfiles</h1>

<p align="center">
  A generic, <b>public-safe</b> macOS provisioner — one TUI, two jobs:<br>
  set up a fresh Mac, or migrate an existing one.
</p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <img alt="Platform: macOS" src="https://img.shields.io/badge/platform-macOS-lightgrey.svg">
  <img alt="Built with chezmoi + gum" src="https://img.shields.io/badge/built%20with-chezmoi%20%2B%20gum-5277C3.svg">
  <img alt="Secrets: gitleaks" src="https://img.shields.io/badge/secrets-gitleaks-2ea44f.svg">
</p>

<p align="center">
  <img src="docs/demo.gif" alt="Onboarding flow demo" width="720">
</p>

---

## Quick start

```bash
git clone https://github.com/josediego/dotfiles
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs the minimum (Xcode CLT, Homebrew, `gum`, `chezmoi`, `gitleaks`, `age`),
enables the secret-scanning git hook, and opens the TUI. **No `curl | bash`** — you clone and read
it first.

> On a machine that's already set up, skip the bootstrap and just run `./tui.sh`.

## The onboarding flow

The TUI walks you through a few clear choices, then shows a **dry-run preview before touching
anything**:

<table>
  <tr>
    <td width="50%"><img src="docs/01-menu.png" alt="Main menu" width="100%"><br><sub><b>1.</b> Pick what to do</sub></td>
    <td width="50%"><img src="docs/02-context.png" alt="Machine context" width="100%"><br><sub><b>2.</b> Work or personal (drives templating)</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/03-profiles.png" alt="Profile picker" width="100%"><br><sub><b>3.</b> Choose profiles (<code>base</code> is always in)</sub></td>
    <td width="50%"><img src="docs/04-dryrun.png" alt="Dry-run output" width="100%"><br><sub><b>4.</b> See exactly what will happen</sub></td>
  </tr>
</table>

## What it sets up

- **Dotfiles & secrets:** [`chezmoi`](https://chezmoi.io) — templated per machine (work vs personal),
  with optional [`age`](https://age-encryption.org)-encrypted secrets that are safe to commit.
- **Packages:** declarative `Brewfile`s, one per profile (`base`, `aesthetics`, `languages`, `cloud`,
  `ai`). `base` is always installed.
- **Runtimes:** [`mise`](https://mise.jdx.dev) (node, bun, go — pinned in `dot_config/mise/`).
- **Look & feel:** Ghostty with **Commit Mono** + the **Nord** palette, and the `lambda-classic`
  zsh prompt.
- **macOS defaults:** an opt-in, conservative set of `defaults write` tweaks.

## Two modes

| Mode | What it does |
|------|--------------|
| **Fresh setup** | `gum` asks for context + profiles → `brew bundle` → `chezmoi init --apply` → `mise install`. Idempotent; existing files are backed up to `backups/` first. |
| **Migrate** | `gum` asks for transport (SSH / local), direction (pull / push), source, and which path-sets to move → `rsync` with a dry-run preview and an explicit confirmation. **Hosts and paths are entered at runtime, never stored in the repo.** |

Flags: `--dry-run`, `--non-interactive`, `--work` / `--personal`, `--only "a,b"`.

## Security model

This repo is **public**, so it is built so that **nothing secret or employer-specific ever lands in
git**.

- **No secrets in git, ever.** Private/machine-specific config lives in gitignored `~/.zshrc.local`
  and `~/.gitconfig.local` (see [`templates/`](templates/)). The committed dotfiles only *source* them.
- **Encrypted secrets (optional):** with `age`, real secrets are committed only as `encrypted_*.age`
  blobs — safe even in a public repo. The private key stays at `~/.config/chezmoi/key.txt`
  (gitignored) and is moved between machines over a secure channel, never via git.
- **Scanned twice:** a [`gitleaks`](https://github.com/gitleaks/gitleaks) pre-commit hook **and** a
  GitHub Action on every push/PR. Run the gate yourself anytime with `make scan`.
- **Works the same at a company or at home** — the `--work` context keeps personal tooling off a
  corporate machine and vice versa.

## Make targets

```text
make help       list targets
make lint       shellcheck every script
make test       bats smoke tests
make scan       gitleaks over the whole tree
make doctor     report chezmoi drift (nonzero if out of sync)
```

## Layout

```text
bootstrap.sh            entry point
tui.sh                  the gum TUI (Fresh / Migrate / macOS defaults)
lib/                    common, fresh, migrate, macos helpers
profiles/*.Brewfile     package sets
macos/defaults.sh       guarded, idempotent system tweaks
dot_*                   chezmoi-managed dotfiles (zsh, ghostty, mise, gitconfig, omz theme)
templates/*.example     the shape of the gitignored *.local files
docs/demo.tape          VHS script that regenerates the demo (vhs docs/demo.tape)
.githooks/pre-commit    gitleaks secret scan
.github/workflows/      gitleaks CI
```

## License

MIT — see [LICENSE](LICENSE).
