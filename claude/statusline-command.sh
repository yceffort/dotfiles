#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
effort=$(jq -r '.effortLevel // "medium"' "$HOME/.claude/settings.json" 2>/dev/null)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dirname=$(basename "$dir")
branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
now=$(date +%H:%M)

config_file="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}"
config_file="${config_file:-$HOME/.claude.json}"
email=$(jq -r '.oauthAccount.emailAddress // empty' "$config_file" 2>/dev/null)

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
month_pct=$(echo "$input" | jq -r '.rate_limits.monthly.used_percentage // empty')
month_reset=$(echo "$input" | jq -r '.rate_limits.monthly.resets_at // empty')

tokens_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
tokens_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
  elapsed=$(( duration_ms / 1000 ))
  if [ "$elapsed" -ge 3600 ]; then
    session_dur="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
  else
    session_dur="$(( elapsed / 60 ))m"
  fi
fi

ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')


git_counts=$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | awk '
  NF==0 { next }
  {
    x=substr($0,1,1); y=substr($0,2,1)
    if (x=="?") u++
    else if (x=="D" || y=="D") d++
    else if (x!=" ") s++
    else m++
  }
  END { printf "%d %d %d %d", u+0, s+0, m+0, d+0 }
')
set -- $git_counts
git_untracked=$1; git_staged=$2; git_modified=$3; git_deleted=$4

git_ab=$(git -C "$dir" --no-optional-locks rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
git_behind=$(echo "$git_ab" | cut -f1)
git_ahead=$(echo "$git_ab" | cut -f2)

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
  else printf '%b' "\033[38;5;117m"
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

if [ -n "$email" ]; then
  printf '%b' "\033[38;5;214m${email}${c_reset}$sep"
fi
printf '%b' "${c_magenta}${dirname}${c_reset}"
if [ -n "$branch" ]; then
  git_extra=""
  if [ "$git_ahead" -gt 0 ] 2>/dev/null; then
    git_extra="$git_extra ${c_green}↑${git_ahead}${c_reset}"
  fi
  if [ "$git_behind" -gt 0 ] 2>/dev/null; then
    git_extra="$git_extra ${c_yellow}↓${git_behind}${c_reset}"
  fi
  if [ "$git_staged" -gt 0 ] 2>/dev/null; then
    git_extra="$git_extra ${c_green}+${git_staged}${c_reset}"
  fi
  if [ "$git_modified" -gt 0 ] 2>/dev/null; then
    git_extra="$git_extra ${c_yellow}~${git_modified}${c_reset}"
  fi
  if [ "$git_deleted" -gt 0 ] 2>/dev/null; then
    git_extra="$git_extra ${c_red}-${git_deleted}${c_reset}"
  fi
  if [ "$git_untracked" -gt 0 ] 2>/dev/null; then
    git_extra="$git_extra ${c_gray}?${git_untracked}${c_reset}"
  fi
  printf '%b' " ${c_blue}(${branch}${c_reset}${git_extra}${c_blue})${c_reset}"
fi
if [ -n "$node_ver" ]; then
  printf '%b' "$sep"
  printf '%b' "${c_green}node@${node_ver}${c_reset}"
fi
printf '%b' "$sep"
case "$effort" in
  low)    effort_color="$c_gray" ;;
  medium) effort_color="$c_blue" ;;
  high)   effort_color="$c_cyan" ;;
  xhigh)  effort_color="$c_yellow" ;;
  max)    effort_color="$c_red" ;;
  *)      effort_color="$c_gray" ;;
esac
printf '%b' "${c_cyan}${model}${c_reset} ${effort_color}[${effort}]${c_reset}"

printf '\n'
line2_started=0
line2_sep() {
  if [ "$line2_started" -eq 0 ]; then
    line2_started=1
  else
    printf '%b' "$sep"
  fi
}

if [ -n "$five_pct" ]; then
  line2_sep
  five_info="5h: $(printf '%.0f' "$five_pct")%"
  if [ -n "$five_reset" ]; then
    five_info="$five_info (~$(date -r "${five_reset%.*}" '+%H:%M'))"
  fi
  printf '%b' "$(usage_color "$five_pct")${five_info}${c_reset}"
fi
if [ -n "$week_pct" ]; then
  line2_sep
  week_info="Week: $(printf '%.0f' "$week_pct")%"
  if [ -n "$week_reset" ]; then
    week_info="$week_info (~$(date -r "${week_reset%.*}" '+%a %m/%d %H:%M'))"
  fi
  printf '%b' "$(usage_color "$week_pct")${week_info}${c_reset}"
fi
if [ -n "$month_pct" ]; then
  line2_sep
  month_info="월간: $(printf '%.0f' "$month_pct")%"
  if [ -n "$month_reset" ]; then
    month_info="$month_info (~$(date -r "${month_reset%.*}" '+%m/%d %H:%M'))"
  fi
  printf '%b' "$(usage_color "$month_pct")${month_info}${c_reset}"
fi

if [ -n "$tokens_in" ] && [ -n "$tokens_out" ]; then
  line2_sep
  printf '%b' "${c_gray}↑$(fmt_tokens "$tokens_in") ↓$(fmt_tokens "$tokens_out")${c_reset}"
fi
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  line2_sep
  printf '%b' "${c_green}\$$(printf '%.2f' "$cost")${c_reset}"
fi

if [ -n "$session_dur" ]; then
  line2_sep
  printf '%b' "${c_yellow}${session_dur}${c_reset}"
fi
if [ -n "$ctx_used" ]; then
  line2_sep
  printf '%b' "$(usage_color "$ctx_used")context window: $(printf '%.0f' "$ctx_used")%${c_reset}"
fi

