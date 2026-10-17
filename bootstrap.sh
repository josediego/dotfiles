#!/usr/bin/env bash
# Entry point. Safe on a brand-new Mac. Installs the minimum, then launches the TUI.
#
#   git clone https://github.com/<you>/dotfiles && cd dotfiles && ./bootstrap.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "› dotfiles bootstrap"

# 1) Xcode Command Line Tools (git + compilers)
if ! xcode-select -p >/dev/null 2>&1; then
  echo "› installing Xcode Command Line Tools — accept the GUI prompt, then re-run ./bootstrap.sh"
  xcode-select --install || true
  exit 0
fi

# 2) Homebrew (official installer)
if ! command -v brew >/dev/null 2>&1; then
  echo "› installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"

# 3) the installer's own dependencies (idempotent)
for t in gum chezmoi gitleaks age; do
  command -v "$t" >/dev/null 2>&1 || brew install "$t"
done

# 4) enable the secret-scanning pre-commit hook for this clone
git -C "$ROOT" config core.hooksPath .githooks 2>/dev/null || true

# 5) hand off to the TUI
exec "$ROOT/tui.sh" "$@"
