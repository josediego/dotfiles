#!/usr/bin/env bash
# Migrate flow: move code/config/state from another machine (SSH) or a local path.
# Everything is parameterized at runtime — no hosts/paths are stored in the repo.
# shellcheck source=lib/common.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Generic dev excludes — regenerable, never worth transferring.
RSYNC_EXCLUDES=(
  --exclude node_modules --exclude .next --exclude .turbo
  --exclude build --exclude dist --exclude out --exclude .cache
  --exclude '*.log' --exclude .DS_Store
)

# Path-sets offered in the TUI. Each value is one-or-more home-rooted entries.
declare -A PATHSETS=(
  [workspace]="workspace"
  [config]=".config"
  [dotfiles]=".zshrc .zshrc.local .gitconfig .gitconfig.local"
  [claude]=".claude .claude.json"
)

_best_rsync() { [ -x /opt/homebrew/bin/rsync ] && echo /opt/homebrew/bin/rsync || echo rsync; }

# _transfer <dry:0|1> <src> <dst>
_transfer() {
  local dry="$1" src="$2" dst="$3"
  local RSYNC; RSYNC="$(_best_rsync)"
  local -a opts=(-az "${RSYNC_EXCLUDES[@]}")
  [ "$dry" = "1" ] && opts+=(--dry-run --itemize-changes)
  [ "$TRANSPORT" = "ssh" ] && opts+=(-e "ssh -o StrictHostKeyChecking=accept-new")
  run "$RSYNC" "${opts[@]}" "$src" "$dst"
}

# Resolve (src, dst) for one home-rooted entry. All entries are top-level under $HOME,
# so the destination is always the home directory of the receiving side.
_pair() {
  local rel="$1"
  case "$TRANSPORT:$DIRECTION" in
    ssh:pull)   echo "$REMOTE:$rel" "$HOME/" ;;
    ssh:push)   echo "$HOME/$rel" "$REMOTE:" ;;
    local:pull) echo "$REMOTE/$rel" "$HOME/" ;;
    local:push) echo "$HOME/$rel" "$REMOTE/" ;;
    *) die "unknown transport/direction: $TRANSPORT/$DIRECTION" ;;
  esac
}

# migrate_run <transport: ssh|local> <direction: pull|push> <remote> <set> [set...]
migrate_run() {
  TRANSPORT="$1"; DIRECTION="$2"; REMOTE="$3"; shift 3
  local -a sets=("$@")

  info "Migrate — ${DIRECTION} via ${TRANSPORT} — ${REMOTE}"
  info "Sets: ${sets[*]}"

  # collect the list of entries to move
  local -a rels=()
  local set rel
  for set in "${sets[@]}"; do
    for rel in ${PATHSETS[$set]}; do rels+=("$rel"); done
  done

  # 1) preview (always dry)
  info "Preview (dry-run):"
  local src dst
  for rel in "${rels[@]}"; do
    read -r src dst < <(_pair "$rel")
    _transfer 1 "$src" "$dst" || warn "preview failed for $rel (source may not exist)"
  done

  # 2) confirm, then do it for real (still honors global DRY_RUN via run())
  echo
  warn "You are responsible for any sensitive files in the selected sets."
  if ! confirm "Run the transfer above for real?"; then
    warn "aborted; nothing moved."
    return 0
  fi
  for rel in "${rels[@]}"; do
    read -r src dst < <(_pair "$rel")
    info "transfer: $src → $dst"
    _transfer 0 "$src" "$dst" || warn "transfer failed for $rel"
  done
  ok "Migrate complete."
}
