#!/bin/bash
# Offline tests for pr-workflow's hooks. Run: bash plugins/pr-workflow/tests/test-hooks.sh
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
guard="$here/hooks/pr-guard.sh"
reset="$here/hooks/session-reset.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export CLAUDE_PLUGIN_DATA="$tmp/data"
export CLAUDE_PLUGIN_OPTION_AUTHOR_REPOS="Owner/Alpha, owner/beta"
export CLAUDE_PLUGIN_OPTION_INTAKE_REPOS="owner/alpha"

# A git checkout whose origin is a configured repo, and one that isn't.
git init -q "$tmp/alpha" && git -C "$tmp/alpha" remote add origin git@github-alias:owner/alpha.git
git init -q "$tmp/other" && git -C "$tmp/other" remote add origin https://github.com/someone/else.git

pass=0; fail=0
run() { # session agent cwd command -> prints hook stdout
  jq -n --arg s "$1" --arg a "$2" --arg c "$3" --arg cmd "$4" \
    '{session_id:$s, cwd:$c, hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}} + (if $a == "" then {} else {agent_id:$a} end)' \
    | "$BASH" "$guard"
}
expect() { # name expected(deny|none) output
  local got=none
  printf '%s' "$3" | grep -q '"permissionDecision": *"deny"' && got=deny
  if [ "$got" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (expected $2, got $got): $3"; fi
}

expect "first call to a configured repo via -R"      deny "$(run s1 '' "$tmp/other" 'gh pr view 1 -R owner/alpha')"
expect "second call, same session and repo"          none "$(run s1 '' "$tmp/other" 'gh pr comment 1 -R owner/alpha -b hi')"
expect "second configured repo gets its own"          deny "$(run s1 '' "$tmp/other" 'gh pr view 2 --repo owner/beta')"
expect "unconfigured repo"                            none "$(run s1 '' "$tmp/other" 'gh pr view 3 -R someone/else')"
expect "repo from cwd remote (ssh alias)"             deny "$(run s2 '' "$tmp/alpha" 'gh pr list')"
expect "gh api implicit POST, endpoint path"          deny "$(run s3 '' "$tmp/other" 'gh api repos/owner/alpha/issues/1/comments -f body=x')"
expect "github URL argument"                          deny "$(run s4 '' "$tmp/other" 'gh pr view https://github.com/owner/beta/pull/7')"
expect "compound command with cd"                     deny "$(run s5 '' "$tmp/other" 'cd /x && gh pr checks 4 -R OWNER/ALPHA')"
expect "not a gh call"                                none "$(run s6 '' "$tmp/alpha" 'echo gh pr view; ghost run')"
expect "subagent after main was reminded"             none "$(run s1 agentA "$tmp/other" 'gh pr diff 1 -R owner/alpha')"
expect "subagent, repo the main session hasn't seen"  deny "$(run s7 agentB "$tmp/other" 'gh pr diff 1 -R owner/alpha')"
expect "same subagent again"                          none "$(run s7 agentB "$tmp/other" 'gh pr diff 1 -R owner/alpha')"
expect "another subagent, same repo"                  deny "$(run s7 agentC "$tmp/other" 'gh pr diff 1 -R owner/alpha')"
expect "agent record doesn't count for main"          deny "$(run s7 '' "$tmp/other" 'gh pr view 1 -R owner/alpha')"
expect "env prefix before gh"                         deny "$(run s10 '' "$tmp/other" 'GH_PAGER=cat gh pr view 1 -R owner/alpha')"
expect "body URL to another repo, cwd configured"     deny "$(run r1 '' "$tmp/alpha" 'gh pr comment 5 --body "overlaps https://github.com/x/other/pull/3"')"
expect "body text repos/a/b, cwd configured"          deny "$(run r2 '' "$tmp/alpha" 'gh pr comment 5 --body "see repos/a/b for details"')"
expect "body text -R a/b, cwd configured"             deny "$(run r3 '' "$tmp/alpha" 'gh pr create --title t --body "use -R a/b to target"')"
expect "heredoc body URL, cwd configured"             deny "$(run r4 '' "$tmp/alpha" "$(printf 'gh pr create --body-file - <<EOF\nsee github.com/x/y\nEOF')")"
expect "cd into a configured checkout, no -R"         deny "$(run r5 '' "$tmp/other" "cd $tmp/alpha && gh pr view 1")"
expect "cd with quoted path"                          deny "$(run r6 '' "$tmp/other" "cd '$tmp/alpha'; gh pr view 1")"
expect "-R without a separator"                       deny "$(run r7 '' "$tmp/other" 'gh pr view 1 -Rowner/alpha')"
expect "body links a second configured repo"          deny "$(run r8 '' "$tmp/other" 'gh pr comment 5 -R owner/alpha --body "see github.com/owner/beta/pull/1"')"
expect "second call: the other configured repo next"  deny "$(run r8 '' "$tmp/other" 'gh pr comment 5 -R owner/alpha --body "see github.com/owner/beta/pull/1"')"
expect "third call: both seen"                        none "$(run r8 '' "$tmp/other" 'gh pr comment 5 -R owner/alpha --body "see github.com/owner/beta/pull/1"')"
expect "malformed input"                              none "$(printf 'not json' | "$BASH" "$guard")"
expect "no plugin data dir"                           none "$(CLAUDE_PLUGIN_DATA='' run s8 '' "$tmp/other" 'gh pr view 1 -R owner/alpha')"

# Reason text names the right skill.
out=$(run s9 '' "$tmp/other" 'gh pr view 1 -R owner/beta')
printf '%s' "$out" | grep -q 'load `pr-workflow:pr-author`, then' && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: author-only reason: $out"; }

# Reset after compaction/clear: reminded again.
printf '{"session_id":"s1","hook_event_name":"SessionStart","source":"compact"}' | "$BASH" "$reset"
expect "reminded again after reset"                   deny "$(run s1 '' "$tmp/other" 'gh pr view 1 -R owner/alpha')"

echo "passed: $pass, failed: $fail"
[ "$fail" = 0 ]
