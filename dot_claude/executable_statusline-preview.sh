#!/bin/zsh
now=$(date +%s)
for p in 12 55 80 95; do
  echo "{\"model\":{\"display_name\":\"Opus 5.5\"},\"workspace\":{\"current_dir\":\"$PWD\"},\"cost\":{\"total_cost_usd\":1.23},\"context_window\":{\"context_window_size\":200000,\"used_percentage\":$p,\"total_input_tokens\":1234567,\"total_output_tokens\":38200,\"current_usage\":{\"input_tokens\":$((p*2000))}},\"rate_limits\":{\"five_hour\":{\"used_percentage\":$p,\"resets_at\":$((now+4800))}}}" | ~/.claude/statusline.sh; echo
done
