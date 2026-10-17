#!/bin/zsh
# Claude Code status line — minimal, Nerd Font glyphs, colored text only.
#
# Reads the Status JSON payload on stdin and prints ONE line:
#   󰚩 model │  dir  branch │ 󰍛 used/size pct │ ↑in ↓out │ 󰊚 5h pct reset │  cost
#
# Every field is best-effort: a missing/renamed field simply doesn't render, so
# the line stays stable across Claude Code versions and schema changes.
# Needs a Nerd Font (Ghostty here falls back to JetBrainsMono NFM).

zmodload zsh/datetime
input="$(cat)"

# One jq pass; fields separated by US (\x1f) so empty values survive.
IFS=$'\x1f' read -r model cwd cost ctx_pct ctx_used ctx_size tok_in tok_out five_h five_reset transcript <<<"$(
  jq -r '
    def s: if . == null then "" else tostring end;
    def epoch:
      if . == null then null
      elif type == "number" then (if . > 1e12 then . / 1000 else . end | floor)
      else (try (sub("\\.[0-9]+"; "") | fromdateiso8601) catch null) end;
    [
      .model.display_name // "",
      (.workspace.current_dir // .cwd // ""),
      (.cost.total_cost_usd | s),
      (.context_window.used_percentage | s),
      ((.context_window.current_usage // null)
        | if . then ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) else null end
        | s),
      (.context_window.context_window_size | s),
      (.context_window.total_input_tokens | s),
      (.context_window.total_output_tokens | s),
      (.rate_limits.five_hour.used_percentage | s),
      (.rate_limits.five_hour.resets_at | epoch | s),
      .transcript_path // ""
    ] | join("\u001f")' 2>/dev/null <<<"$input"
)"
dir="${cwd##*/}"
# Strip control chars so a crafted dir/model name can't inject escape sequences.
dir=${dir//[[:cntrl:]]/}
model=${model//[[:cntrl:]]/}

# --- glyphs ------------------------------------------------------------------
G_MODEL=$'\U000F06A9'   # nf-md-robot
G_DIR=$''         # nf-fa-folder_open
G_BRANCH=$''      # nf-dev-git_branch
G_CTX=$'\U000F035B'     # nf-md-memory
G_GAUGE=$'\U000F029A'   # nf-md-gauge
G_COST=$''        # nf-fa-dollar

# --- colors (256-color, tuned for dark themes like IR Black) -----------------
e=$'\e'
reset="${e}[0m"
fg() { print -n "${e}[38;5;$1m"; }
sep=" $(fg 238)│${reset} "

# Green → yellow → orange → red by percentage.
heat() {
  local p=$1
  if   (( p < 40 )); then print -n 114
  elif (( p < 70 )); then print -n 221
  elif (( p < 90 )); then print -n 209
  else                    print -n 203
  fi
}

# 1234 → 1.2k, 1234567 → 1.2M
human() {
  local n=$1
  if   (( n >= 1000000 )); then printf '%.1fM' $(( n / 1000000.0 ))
  elif (( n >= 1000 ));    then printf '%dk' $(( n / 1000 ))
  else                          print -n "$n"
  fi
}

# --- transcript fallback -----------------------------------------------------
# Older payloads lack context_window; derive it from the transcript instead:
# last request's prompt size, and session totals of input/output tokens.
if [[ ( -z "$ctx_used" || -z "$tok_in" ) && -n "$transcript" && -f "$transcript" ]]; then
  IFS=$'\x1f' read -r t_last t_in t_out <<<"$(jq -rs '
      map(.message.usage? // empty)
      | map({p: ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)),
             o: (.output_tokens // 0)})
      | map(select(.p > 0))
      | [ (last.p // ""), (map(.p) | add // ""), (map(.o) | add // "") ]
      | map(tostring) | join("\u001f")' "$transcript" 2>/dev/null)"
  [[ -z "$ctx_used" ]] && ctx_used=$t_last
  [[ -z "$tok_in"   ]] && tok_in=$t_in
  [[ -z "$tok_out"  ]] && tok_out=$t_out
fi

# --- git branch (+ dirty marker) ---------------------------------------------
# Branch name only, from refs — never touches the worktree. A dirty check
# (diff/status) would run the repo's own clean filters, so a cloned repo's
# .git/config could execute commands on every refresh; fsmonitor is off too.
gitq() {
  git -c core.fsmonitor= --no-optional-locks -C "$cwd" "$@"
}
branch=""
if [[ -n "$cwd" ]] && gitq rev-parse --is-inside-work-tree &>/dev/null; then
  branch="$(gitq symbolic-ref --short HEAD 2>/dev/null \
           || gitq rev-parse --short HEAD 2>/dev/null)"
  branch=${branch//[[:cntrl:]]/}
fi

parts=()

# --- model -------------------------------------------------------------------
[[ -n "$model" ]] && parts+=("$(fg 147)${G_MODEL} ${model}")

# --- dir + branch ------------------------------------------------------------
loc=""
[[ -n "$dir"    ]] && loc="$(fg 111)${G_DIR} ${dir}"
[[ -n "$branch" ]] && loc="${loc:+$loc  }$(fg 176)${G_BRANCH} ${branch}"
[[ -n "$loc"    ]] && parts+=("$loc")

# --- context: used/size pct --------------------------------------------------
size=${ctx_size:-200000}
pct=""
if [[ -n "$ctx_pct" ]]; then
  pct=${ctx_pct%%.*}
elif [[ -n "$ctx_used" && "$ctx_used" -gt 0 ]] 2>/dev/null; then
  pct=$(( ctx_used * 100 / size ))
fi
if [[ -n "$pct" ]]; then
  (( pct > 100 )) && pct=100
  ctx="$(fg 250)${G_CTX} "
  [[ -n "$ctx_used" ]] && ctx+="$(human $ctx_used)$(fg 242)/$(human $size) "
  ctx+="$(fg $(heat $pct))${pct}%"
  parts+=("$ctx")
fi

# --- session tokens ----------------------------------------------------------
if [[ -n "$tok_in" || -n "$tok_out" ]]; then
  parts+=("$(fg 245)↑$(fg 252)$(human ${tok_in:-0}) $(fg 245)↓$(fg 252)$(human ${tok_out:-0})")
fi

# --- 5h block: pct + time to reset -------------------------------------------
if [[ -n "$five_h" ]]; then
  p=${five_h%%.*}
  blk="$(fg $(heat $p))${G_GAUGE} ${p}%"
  if [[ -n "$five_reset" ]]; then
    left=$(( five_reset - EPOCHSECONDS ))
    if (( left > 0 )); then
      h=$(( left / 3600 )); m=$(( left % 3600 / 60 ))
      (( h > 0 )) && t="${h}h${m}m" || t="${m}m"
      blk+=" $(fg 242)${t}"
    fi
  fi
  parts+=("$blk")
fi

# --- cost (dim, last) --------------------------------------------------------
[[ -n "$cost" ]] && parts+=("$(fg 242)${G_COST} $(printf '%.2f' "$cost" 2>/dev/null || print -n "$cost")")

print -n -- "${(pj:$sep:)parts}${reset}"
