#!/usr/bin/env bash
# Shared helpers for the installer. Sourced by tui.sh and the other lib/*.sh.
# shellcheck disable=SC2155

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DOTFILES_ROOT

DRY_RUN="${DRY_RUN:-0}"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"

# ── logging ──
log()  { printf '  %s\n' "$*"; }
info() { printf '\033[1;36m›\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# run CMD, or just print it under DRY_RUN=1 (home path shown as ~, never absolute)
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '\033[2m[dry-run]\033[0m %s\n' "${*//$HOME/~}"
  else
    "$@"
  fi
}

# confirm "question" → 0 yes / 1 no. Uses gum when present; auto-yes when non-interactive.
confirm() {
  local q="$1"
  [ "$NON_INTERACTIVE" = "1" ] && return 0
  if has gum; then
    gum confirm "$q"
  else
    local a
    read -r -p "$q [y/N] " a
    [[ "$a" =~ ^[Yy]$ ]]
  fi
}

# Back up an existing, real (non-symlink) file before it gets replaced.
backup_if_exists() {
  local target="$1"
  { [ -e "$target" ] && [ ! -L "$target" ]; } || return 0
  local dir="$DOTFILES_ROOT/backups/$(date +%Y%m%d-%H%M%S)"
  run mkdir -p "$dir"
  run cp -a "$target" "$dir/"
  warn "backed up ${target/#$HOME/~} → ${dir/#$HOME/~}/"
}

# brew bundle with a per-package fallback so one bad formula/cask ≠ the whole run.
brew_bundle_resilient() {
  local file="$1"
  export HOMEBREW_DOWNLOAD_CONCURRENCY=1   # HB6: avoid concurrent DMG mount collisions
  if [ "$DRY_RUN" = "1" ]; then
    run brew bundle --file "$file" --no-lock --verbose
    return 0
  fi
  if brew bundle --file "$file" --no-lock; then
    return 0
  fi
  warn "brew bundle had failures; retrying missing entries individually…"
  local type rest name
  while read -r type rest; do
    rest="${rest#\"}"; name="${rest%%\"*}"
    case "$type" in
      brew) brew install "$name" || warn "failed: brew $name" ;;
      cask) brew install --cask "$name" || warn "failed: cask $name" ;;
    esac
  done < <(grep -E '^(brew|cask) "' "$file")
}
