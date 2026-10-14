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

@test "no tracked file contains the employer domain" {
  # Needle is split so this test file does not itself contain the literal string.
  run bash -c 'grep -rIl "employer""-domain" "$DOTFILES_ROOT" --exclude-dir=.git || true'
  [ -z "$output" ]
}
