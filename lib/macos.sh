#!/usr/bin/env bash
# Thin wrapper: confirm, then run the guarded macOS defaults script.
# shellcheck source=lib/common.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

macos_run() {
  local script="$DOTFILES_ROOT/macos/defaults.sh"
  [ -f "$script" ] || { warn "no macos/defaults.sh found"; return 0; }
  [ "$(uname)" = "Darwin" ] || { warn "not macOS; skipping defaults"; return 0; }
  if confirm "Apply macOS system defaults (keyboard, Finder, Dock, screenshots)?"; then
    DRY_RUN="$DRY_RUN" bash "$script"
  else
    log "skipped macOS defaults."
  fi
}
