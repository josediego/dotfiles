#!/usr/bin/env bash
# The macro TUI: "what do you want to do with this machine?" → Fresh | Migrate | macOS defaults.
# shellcheck source=lib/common.sh
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT
source "$DOTFILES_ROOT/lib/common.sh"

WORK_FLAG=""
ONLY=""

usage() {
  cat <<'EOF'
Usage: ./tui.sh [flags]
  --dry-run            Preview actions without changing anything
  --non-interactive    Assume "yes"; use defaults (base+aesthetics) for Fresh
  --work | --personal  Preselect machine context (skips the context prompt)
  --only "a,b"         Fresh: use exactly these extra profiles (skips the picker)
  -h, --help           Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --non-interactive) NON_INTERACTIVE=1 ;;
    --work) WORK_FLAG=work ;;
    --personal) WORK_FLAG=personal ;;
    --only) ONLY="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done
export DRY_RUN NON_INTERACTIVE

has gum || die "gum is required — run ./bootstrap.sh first."

# newline-separated list → array (skips blanks)
_lines_to_array() {
  local line
  while IFS= read -r line; do [ -n "$line" ] && printf '%s\n' "$line"; done
}

do_fresh() {
  source "$DOTFILES_ROOT/lib/fresh.sh"

  local context="$WORK_FLAG"
  if [ -z "$context" ]; then
    if [ "$NON_INTERACTIVE" = "1" ]; then
      context="personal"
    else
      context="$(gum choose --header "Machine context:" "personal" "work")"
    fi
  fi

  local -a profiles=(base)
  local extras
  if [ -n "$ONLY" ]; then
    extras="${ONLY//,/$'\n'}"
  elif [ "$NON_INTERACTIVE" = "1" ]; then
    extras="aesthetics"
  else
    extras="$(printf '%s\n' aesthetics languages cloud ai \
      | gum choose --no-limit --header "Extra profiles (base is always included):")"
  fi
  local p
  while IFS= read -r p; do [ -n "$p" ] && profiles+=("$p"); done < <(printf '%s\n' "$extras" | _lines_to_array)

  fresh_run "$context" "${profiles[@]}"
}

do_migrate() {
  source "$DOTFILES_ROOT/lib/migrate.sh"

  local transport direction remote
  transport="$(gum choose --header "Transport:" "ssh" "local")"
  direction="$(gum choose --header "Direction:" "pull (into this Mac)" "push (to the target)")"
  direction="${direction%% *}"   # "pull" | "push"
  remote="$(gum input --header "Source/target for ${transport}:" \
    --placeholder "user@host   or   /Volumes/Backup")"
  [ -n "$remote" ] || die "no source/target given."

  local -a sets=()
  local s
  while IFS= read -r s; do [ -n "$s" ] && sets+=("$s"); done < <(
    printf '%s\n' workspace config dotfiles claude \
      | gum choose --no-limit --header "What to move:" | _lines_to_array)
  [ "${#sets[@]}" -gt 0 ] || die "nothing selected."

  migrate_run "$transport" "$direction" "$remote" "${sets[@]}"
}

main() {
  local choice
  if [ "$NON_INTERACTIVE" = "1" ]; then
    do_fresh; return
  fi
  choice="$(gum choose --header "What do you want to do with this machine?" \
    "Fresh setup (from scratch)" \
    "Migrate (from another machine)" \
    "Apply macOS defaults" \
    "Quit")"
  case "$choice" in
    "Fresh setup"*) do_fresh ;;
    "Migrate"*) do_migrate ;;
    "Apply macOS defaults") source "$DOTFILES_ROOT/lib/macos.sh"; macos_run ;;
    *) exit 0 ;;
  esac
}

main
