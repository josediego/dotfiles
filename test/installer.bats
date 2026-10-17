#!/usr/bin/env bats
# Smoke tests for the installer helpers. We do NOT source common.sh at the top
# level because bats defines its own `run`; instead we exercise helpers inside
# `bash -c` subshells.

setup() {
  export DOTFILES_ROOT
  DOTFILES_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "has() detects an existing binary" {
  run bash -c 'source "$DOTFILES_ROOT/lib/common.sh"; has bash'
  [ "$status" -eq 0 ]
}

@test "has() rejects a missing binary" {
  run bash -c 'source "$DOTFILES_ROOT/lib/common.sh"; has definitely-not-real-xyz'
  [ "$status" -ne 0 ]
}

@test "run() does nothing under DRY_RUN" {
  local marker="$BATS_TEST_TMPDIR/should-not-exist"
  run bash -c 'DRY_RUN=1; source "$DOTFILES_ROOT/lib/common.sh"; run touch "'"$marker"'"'
  [ "$status" -eq 0 ]
  [ ! -e "$marker" ]
}

@test "every Brewfile has only valid directives" {
  for f in "$DOTFILES_ROOT"/profiles/*.Brewfile; do
    run grep -Evq '^\s*($|#|brew |cask |tap )' "$f"
    [ "$status" -ne 0 ]  # grep found no invalid line
  done
}

@test "no tracked file contains a blocklisted term" {
  # Terms live outside the repo so they are never committed themselves.
  local blocklist="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/blocklist"
  [ -s "$blocklist" ] || skip "no blocklist at $blocklist"
  local terms
  terms="$(grep -Ev '^[[:space:]]*(#|$)' "$blocklist" || true)"
  [ -n "$terms" ] || skip "blocklist is empty"
  run bash -c 'cd "$DOTFILES_ROOT" && git ls-files -z | xargs -0 grep -IilwF -e "$1" || true' _ "$terms"
  [ -z "$output" ]
}
