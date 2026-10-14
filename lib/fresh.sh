#!/usr/bin/env bash
# Fresh-setup flow: packages (by profile) → dotfiles (chezmoi) → runtimes (mise).
# shellcheck source=lib/common.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# fresh_run <context: work|personal> <profile> [profile...]
fresh_run() {
  local context="$1"; shift
  local -a profiles=("$@")

  info "Fresh setup — context: ${context} — profiles: ${profiles[*]}"
  has brew || die "Homebrew is required (run ./bootstrap.sh first)."

  # 1) packages, one Brewfile per profile
  local p bf
  for p in "${profiles[@]}"; do
    bf="$DOTFILES_ROOT/profiles/${p}.Brewfile"
    [ -f "$bf" ] || { warn "no Brewfile for profile '${p}', skipping"; continue; }
    info "brew bundle: ${p}"
    brew_bundle_resilient "$bf"
  done

  # 2) oh-my-zsh (prereq of the managed .zshrc) — install BEFORE chezmoi applies .zshrc
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "installing oh-my-zsh"
    run sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi

  # 3) dotfiles via chezmoi (backs up any real files first)
  has chezmoi || die "chezmoi is missing (the base profile installs it)."
  backup_if_exists "$HOME/.zshrc"
  backup_if_exists "$HOME/.gitconfig"
  backup_if_exists "$HOME/.config/ghostty/config"
  info "applying dotfiles with chezmoi"
  local work=false
  [ "$context" = "work" ] && work=true
  run chezmoi init --apply --source "$DOTFILES_ROOT" --promptBool "work=${work}"

  # 4) runtimes — the chezmoi run_onchange script calls `mise install`; do it explicitly too
  if has mise; then
    info "installing mise runtimes"
    run mise install
  fi

  ok "Fresh setup complete. Open a new terminal to load the new shell."
}
