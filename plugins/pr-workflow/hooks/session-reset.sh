#!/bin/bash
# pr-workflow SessionStart hook (compact|clear): the loaded rules may be gone
# from context, so forget this session's reminders and remind again.
trap 'exit 0' ERR
input=$(cat) || exit 0
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
data=${CLAUDE_PLUGIN_DATA:-}
[ -n "$session" ] && [ -n "$data" ] || exit 0
safe_session=$(printf '%s' "$session" | tr -c 'A-Za-z0-9_-' '_')
rm -rf -- "$data/seen/$safe_session"
exit 0
