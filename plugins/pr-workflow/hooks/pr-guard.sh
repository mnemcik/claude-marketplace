#!/bin/bash
# pr-workflow PreToolUse hook (Bash). Before the first gh call that touches a
# configured repo, deny once and name the PR rules to load. A reminder, not a
# gate: the retry passes. Never returns "allow". Fails open on any error.
#
# Records live in $CLAUDE_PLUGIN_DATA/seen/<session_id>/:
#   main/<repo>            the main session was reminded for <repo>
#   agents/<agent_id>/<repo>  a subagent or in-process teammate was reminded
# A subagent's call passes when the main session already has the record
# (the parent briefs it); otherwise it gets one neutral reminder.

trap 'exit 0' ERR
input=$(cat) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
agent=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] && [ -n "$session" ] || exit 0

# Only commands that invoke gh as a program (at command position, optionally
# after VAR=value prefixes). gh inside scripts, xargs or sh -c isn't seen.
printf '%s' "$cmd" | grep -Eq '(^|[;&|(`]|\$\()[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*gh[[:space:]]' || exit 0

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
re='[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+'

remote_of() { # $1 = directory -> owner/repo of its origin remote, or nothing
  local url r
  [ -n "$1" ] && [ -d "$1" ] || return 0
  url=$(git -C "$1" remote get-url origin 2>/dev/null) || return 0
  r=$(printf '%s' "$url" | sed -E 's#^.*[:/]([^/:]+/[^/]+)$#\1#; s#\.git$##')
  printf '%s' "$r" | grep -Eq "^$re$" && printf '%s\n' "$r"
  return 0
}

cd_remotes() { # stdin: cd targets -> their origin repos
  local d
  while IFS= read -r d; do
    case "$d" in
      "~"*) d="$HOME${d#\~}" ;;
      /*) ;;
      *) d="$cwd/$d" ;;
    esac
    remote_of "$d"
  done
}

# Every repo the command may touch, most specific first. Text in a body can
# add candidates; it never hides one (each configured candidate is checked).
candidates=$(
  printf '%s' "$cmd" | grep -Eo -- "(-R|--repo)[= ]*[\"']?$re" | sed -E "s/^(-R|--repo)[= ]*[\"']?//"
  printf '%s\n' "$cmd" | grep -Eo "(^|[;&|(])[[:space:]]*cd[[:space:]]+(\"[^\"]*\"|'[^']*'|[^[:space:];&|)]+)" \
    | sed -E "s/^[;&|(]?[[:space:]]*cd[[:space:]]+//; s/^[\"']//; s/[\"']$//" \
    | cd_remotes
  remote_of "$cwd"
  printf '%s' "$cmd" | grep -Eo "repos/$re" | sed 's#^repos/##'
  printf '%s' "$cmd" | grep -Eo "github\.com[/:]$re" | sed -E 's#^github\.com[/:]##'
)
[ -n "$candidates" ] || exit 0

in_list() { # $1 = repo, $2 = comma-separated list
  local item items
  IFS=',' read -ra items <<< "$2"
  for item in "${items[@]}"; do
    item=$(lower "$(printf '%s' "$item" | tr -d '[:space:]')")
    [ -n "$item" ] && [ "$item" = "$1" ] && return 0
  done
  return 1
}

data=${CLAUDE_PLUGIN_DATA:-}
[ -n "$data" ] || exit 0
safe_session=$(printf '%s' "$session" | tr -c 'A-Za-z0-9_-' '_')
base="$data/seen/$safe_session"
safe_agent=$(printf '%s' "$agent" | tr -c 'A-Za-z0-9_-' '_')

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# The first configured candidate this session (or agent) hasn't been reminded of.
repo=""
for cand in $candidates; do
  cand=$(lower "${cand%.git}")
  author=0; intake=0
  in_list "$cand" "${CLAUDE_PLUGIN_OPTION_AUTHOR_REPOS:-}" && author=1
  in_list "$cand" "${CLAUDE_PLUGIN_OPTION_INTAKE_REPOS:-}" && intake=1
  [ $author = 1 ] || [ $intake = 1 ] || continue
  key=$(printf '%s' "$cand" | tr '/' '_')
  main_rec="$base/main/$key"
  [ -e "$main_rec" ] && continue
  if [ -n "$agent" ]; then
    agent_rec="$base/agents/$safe_agent/$key"
    [ -e "$agent_rec" ] && continue
  fi
  repo=$cand
  break
done
[ -n "$repo" ] || exit 0

if [ -z "$agent" ]; then
  mkdir -p "$base/main" && : > "$main_rec" || exit 0
  if [ $author = 1 ] && [ $intake = 1 ]; then
    which="load \`pr-workflow:pr-author\` if this session opened the PR, \`pr-workflow:pr-intake\` otherwise"
  elif [ $author = 1 ]; then
    which="load \`pr-workflow:pr-author\`"
  else
    which="load \`pr-workflow:pr-intake\` (or \`pr-workflow:pr-author\` if this session opened the PR)"
  fi
  deny "PR rules apply in $repo: $which, then retry this command. (pr-workflow reminds once per session and repo.)"
else
  mkdir -p "$base/agents/$safe_agent" && : > "$agent_rec" || exit 0
  deny "PR rules apply in $repo: load \`pr-workflow:pr-author\` if your brief makes you the PR's author, \`pr-workflow:pr-intake\` if you review for the maintainer; read-only work needs neither. Then retry this command."
fi
