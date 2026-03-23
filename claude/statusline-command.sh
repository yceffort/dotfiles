#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dirname=$(basename "$dir")
branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
now=$(date +%H:%M)

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
month_pct=$(echo "$input" | jq -r '.rate_limits.monthly.used_percentage // empty')

tokens_in=$(echo "$input" | jq -r '.session.tokens_in // empty')
tokens_out=$(echo "$input" | jq -r '.session.tokens_out // empty')
cost=$(echo "$input" | jq -r '.session.cost_usd // empty')

session_start=$(echo "$input" | jq -r '.session.start_time // empty')
if [ -n "$session_start" ]; then
  elapsed=$(( $(date +%s) - ${session_start%.*} ))
  if [ "$elapsed" -ge 3600 ]; then
    session_dur="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
  else
    session_dur="$(( elapsed / 60 ))m"
  fi
fi

ctx_used=$(echo "$input" | jq -r '.session.context_window.used_percentage // empty')

last_commit_ts=$(git -C "$dir" --no-optional-locks log -1 --format=%ct 2>/dev/null)
if [ -n "$last_commit_ts" ]; then
  ago=$(( $(date +%s) - last_commit_ts ))
  if [ "$ago" -ge 86400 ]; then last_commit="$(( ago / 86400 ))d ago"
  elif [ "$ago" -ge 3600 ]; then last_commit="$(( ago / 3600 ))h ago"
  else last_commit="$(( ago / 60 ))m ago"
  fi
fi

git_dirty=$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')

node_ver=$(node -v 2>/dev/null | tr -d 'v')

c_cyan="\033[36m"
c_yellow="\033[33m"
c_green="\033[32m"
c_magenta="\033[35m"
c_blue="\033[34m"
c_red="\033[31m"
c_white="\033[37m"
c_gray="\033[90m"
c_reset="\033[0m"

usage_color() {
  pct=$1
  if [ "${pct%.*}" -ge 80 ] 2>/dev/null; then printf '%b' "$c_red"
  elif [ "${pct%.*}" -ge 50 ] 2>/dev/null; then printf '%b' "$c_yellow"
  else printf '%b' "$c_green"
  fi
}

fmt_tokens() {
  t=$1
  if [ "$t" -ge 1000000 ] 2>/dev/null; then
    printf '%.1fM' "$(echo "$t / 1000000" | bc -l)"
  elif [ "$t" -ge 1000 ] 2>/dev/null; then
    printf '%.1fK' "$(echo "$t / 1000" | bc -l)"
  else
    printf '%s' "$t"
  fi
}

sep=" ${c_white}|${c_reset} "

printf '%b' "${c_magenta}${dirname}${c_reset}"
if [ -n "$branch" ]; then
  if [ "$git_dirty" -gt 0 ] 2>/dev/null; then
    printf '%b' " ${c_blue}(${branch}${c_reset} ${c_red}*${git_dirty}${c_reset}${c_blue})${c_reset}"
  else
    printf '%b' " ${c_blue}(${branch})${c_reset}"
  fi
fi
printf '%b' "$sep"
printf '%b' "${c_cyan}${model}${c_reset}"
printf '%b' "$sep"
printf '%b' "${c_yellow}${now}${c_reset}"

if [ -n "$five_pct" ]; then
  printf '%b' "$sep"
  printf '%b' "$(usage_color "$five_pct")5h: $(printf '%.0f' "$five_pct")%${c_reset}"
fi
if [ -n "$week_pct" ]; then
  printf '%b' "$sep"
  printf '%b' "$(usage_color "$week_pct")주간: $(printf '%.0f' "$week_pct")%${c_reset}"
fi
if [ -n "$month_pct" ]; then
  printf '%b' "$sep"
  printf '%b' "$(usage_color "$month_pct")월간: $(printf '%.0f' "$month_pct")%${c_reset}"
fi

if [ -n "$tokens_in" ] && [ -n "$tokens_out" ]; then
  printf '%b' "$sep"
  printf '%b' "${c_gray}↑$(fmt_tokens "$tokens_in") ↓$(fmt_tokens "$tokens_out")${c_reset}"
fi
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  printf '%b' "$sep"
  printf '%b' "${c_green}\$${cost}${c_reset}"
fi

if [ -n "$session_dur" ]; then
  printf '%b' "$sep"
  printf '%b' "${c_yellow}${session_dur}${c_reset}"
fi
if [ -n "$ctx_used" ]; then
  printf '%b' "$sep"
  printf '%b' "$(usage_color "$ctx_used")ctx: $(printf '%.0f' "$ctx_used")%${c_reset}"
fi
if [ -n "$last_commit" ]; then
  printf '%b' "$sep"
  printf '%b' "${c_gray}commit ${last_commit}${c_reset}"
fi

if [ -n "$node_ver" ]; then
  printf '%b' "$sep"
  printf '%b' "${c_green}node ${node_ver}${c_reset}"
fi
