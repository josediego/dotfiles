#!/usr/bin/env bash
# Conservative, idempotent macOS defaults. `defaults write` is idempotent by nature
# (writing the same value again is a no-op). No destructive actions (we never wipe
# the Dock). Honors DRY_RUN=1. Note: removing a line here does NOT revert a setting.
set -euo pipefail
DRY_RUN="${DRY_RUN:-0}"

d() { if [ "$DRY_RUN" = "1" ]; then printf '[dry-run] defaults %s\n' "$*"; else defaults "$@"; fi; }

echo "› applying macOS defaults…"

# Keyboard — fast key repeat
d write NSGlobalDomain KeyRepeat -int 2
d write NSGlobalDomain InitialKeyRepeat -int 15

# Text — no autocorrect / smart substitutions (annoying while coding)
d write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
d write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
d write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Finder — show extensions, path bar, status bar, POSIX path in title
d write NSGlobalDomain AppleShowAllExtensions -bool true
d write com.apple.finder ShowPathbar -bool true
d write com.apple.finder ShowStatusBar -bool true
d write com.apple.finder _FXShowPosixPathInTitle -bool true

# Screenshots — PNG into ~/Screenshots
[ "$DRY_RUN" = "1" ] || mkdir -p "$HOME/Screenshots"
d write com.apple.screencapture location -string "$HOME/Screenshots"
d write com.apple.screencapture type -string "png"

# Dock — autohide, no recent apps (does NOT touch your pinned apps)
d write com.apple.dock autohide -bool true
d write com.apple.dock show-recents -bool false

# No .DS_Store on network / USB volumes
d write com.apple.desktopservices DSDontWriteNetworkStores -bool true
d write com.apple.desktopservices DSDontWriteUSBStores -bool true

if [ "$DRY_RUN" != "1" ]; then
  for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
fi
echo "✓ macOS defaults applied (some changes need a logout/login)."
