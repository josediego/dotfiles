# dotfiles

A generic, **public-safe** macOS provisioner. One TUI, two jobs:

- **Fresh setup** — pick profiles and leave a new Mac ready (Homebrew + mise + dotfiles + look & feel).
- **Migrate** — move your code/config/state from another machine (over SSH) or a local drive.

It works the same on a personal or a work machine, and it is built so that **nothing secret or
employer-specific ever lands in this repository**.

## Quick start

```bash
git clone https://github.com/josediego/dotfiles
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs the minimum (Xcode CLT, Homebrew, `gum`, `chezmoi`, `gitleaks`, `age`),
enables the secret-scanning git hook, and opens the TUI. No `curl | bash` for this tool — you clone
and read it first.

## What it sets up

- **Dotfiles & secrets:** [`chezmoi`](https://chezmoi.io) — templated per machine (work vs personal),
  with optional `age`-encrypted secrets that are safe to commit.
- **Packages:** declarative `Brewfile`s, one per profile (`base`, `aesthetics`, `languages`, `cloud`,
  `ai`). `base` is always installed.
- **Runtimes:** [`mise`](https://mise.jdx.dev) (node, bun, go — pinned in `dot_config/mise/`).
- **Look & feel:** Ghostty with Commit Mono + the Nord palette, and the `lambda-classic` zsh prompt.
- **macOS defaults:** an opt-in, conservative set of `defaults write` tweaks.

## Modes

| Mode | What it does |
|------|--------------|
| Fresh setup | `gum` prompts for context + profiles → `brew bundle` → `chezmoi init --apply` → `mise install`. Idempotent; existing files are backed up to `backups/` first. |
| Migrate | `gum` prompts for transport (SSH / local), direction (pull / push), source, and which path-sets to move → `rsync` with a dry-run preview and an explicit confirmation. Hosts/paths are entered at runtime, never stored. |

Flags: `--dry-run`, `--non-interactive`, `--work` / `--personal`, `--only "a,b"`.

## Security model

- **No secrets in git, ever.** Private/machine-specific config lives in gitignored `~/.zshrc.local`
  and `~/.gitconfig.local` (see `templates/*.example`). The committed dotfiles only *source* them.
- **Encrypted secrets (optional):** with `age`, real secrets are committed only as `encrypted_*.age`
  blobs — safe even in a public repo. The private key stays at `~/.config/chezmoi/key.txt` (gitignored)
  and is moved between machines over a secure channel, never via git. See `.chezmoi.toml.tmpl`.
- **Scanning, twice:** a `gitleaks` pre-commit hook **and** a GitHub Action on every push/PR.
- Run the gate yourself anytime: `make scan`.

## Make targets

```
make help       # list targets
make lint       # shellcheck every script
make test       # bats smoke tests
make scan       # gitleaks over the whole tree
make doctor     # report chezmoi drift (nonzero if out of sync)
```

## Layout

```
bootstrap.sh            entry point
tui.sh                  the gum TUI (Fresh / Migrate / macOS defaults)
lib/                    common, fresh, migrate, macos helpers
profiles/*.Brewfile     package sets
macos/defaults.sh       guarded, idempotent system tweaks
dot_*                   chezmoi-managed dotfiles (zsh, ghostty, mise, gitconfig, omz theme)
templates/*.example     the shape of the gitignored *.local files
.githooks/pre-commit    gitleaks secret scan
.github/workflows/      gitleaks CI
```

## License

MIT — see [LICENSE](LICENSE).
