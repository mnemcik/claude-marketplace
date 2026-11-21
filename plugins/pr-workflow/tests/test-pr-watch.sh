#!/bin/bash
# Offline tests for bin/pr-watch. Run: bash plugins/pr-workflow/tests/test-pr-watch.sh
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
watch="$here/bin/pr-watch"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Stub gh: prints $FIX/<owner>_<name> (already in the --jq output shape);
# a fixture containing FAIL makes the call fail.
mkdir -p "$tmp/bin" "$tmp/fix"
cat > "$tmp/bin/gh" <<'EOF'
#!/bin/bash
owner="" name=""
while [ $# -gt 0 ]; do
  case "$1" in
    -F) case "$2" in owner=*) owner=${2#owner=} ;; name=*) name=${2#name=} ;; esac; shift 2 ;;
    *) shift ;;
  esac
done
f="$FIX/${owner}_${name}"
[ -f "$f" ] || exit 1
grep -q '^FAIL$' "$f" && exit 1
cat "$f"
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" FIX="$tmp/fix" PR_WATCH_MAX_POLLS=1
state="$tmp/state"
w() { "$BASH" "$watch" --interval 0 --state-dir "$state" "$@"; }

pass=0; fail=0
check() { # name expected-exit actual-exit [output grep]
  if [ "$2" = "$3" ] && { [ -z "${5:-}" ] || printf '%s' "$4" | grep -q -- "$5"; }; then pass=$((pass+1))
  else fail=$((fail+1)); echo "FAIL: $1 (exit $3, want $2): $4"; fi
}

pr1='1 updated=2026-11-17T08:00:00Z head=aaaaaaa draft=false review=none merge=BLOCKED ci=SUCCESS comments=1 reviews=0'
pr1b='1 updated=2026-11-17T09:00:00Z head=aaaaaaa draft=false review=none merge=BLOCKED ci=SUCCESS comments=1 reviews=0'
pr2='2 updated=2026-11-17T09:30:00Z head=bbbbbbb draft=false review=none merge=CLEAN ci=PENDING comments=0 reviews=0'

printf '%s\n' "$pr1" > "$FIX/o_a"; : > "$FIX/o_b"

out=$(w o/a,O/B 2>&1); rc=$?
check "first run saves state, no change"           3 $rc "$out" "no earlier state"
out=$(w 'O/B, o/a' 2>&1); rc=$?
check "same set in another order/case: no change"  3 $rc "$out" "watching 1 open PRs"

printf '%s\n' "$pr1b" > "$FIX/o_a"
out=$(w o/a,o/b 2>&1); rc=$?
check "edited comment (updatedAt) is a change"     0 $rc "$out" "> o/a#1 updated=2026-11-17T09:00"
out=$(w o/a,o/b 2>&1); rc=$?
check "not handled: same change reported again"     0 $rc "$out" "> o/a#1 updated=2026-11-17T09:00"

# A change arrives after the report but before --handled.
printf '%s\n' "$pr2" > "$FIX/o_b"
out=$(w --handled o/a,o/b 2>&1); rc=$?
check "--handled saves the reported snapshot"       0 $rc "$out" "handled: 1 open PRs"
out=$(w o/a,o/b 2>&1); rc=$?
check "change after the report is not lost"         0 $rc "$out" "> o/b#2"
w --handled o/a,o/b >/dev/null
out=$(w o/a,o/b 2>&1); rc=$?
check "after handling: quiet"                       3 $rc "$out" "watching 2 open PRs"

: > "$FIX/o_a"
out=$(w o/a,o/b 2>&1); rc=$?
check "a PR closing (zero open in a repo) is a change" 0 $rc "$out" "< o/a#1"
w --handled o/a,o/b >/dev/null

echo FAIL > "$FIX/o_b"
out=$(w o/a,o/b 2>&1); rc=$?
check "failed API call is not 'no PRs'"            3 $rc "$out" "poll failed"
out=$(PR_WATCH_MAX_POLLS=9 w o/a,o/b 2>&1); rc=$?
check "five failures in a row exit 4"              4 $rc "$out" "5 polls in a row failed"
printf '%s\n' "$pr2" > "$FIX/o_b"

out=$(w --handled o/a,o/b 2>&1); rc=$?
check "--handled with nothing pending"              0 $rc "$out" "nothing pending"

out=$("$BASH" "$watch" --interval x --state-dir "$state" o/a 2>&1); rc=$?
check "bad interval"                                1 $rc "$out"
out=$(w 'not a repo' 2>&1); rc=$?
check "no valid repo"                               1 $rc "$out" "no valid owner/repo"

: > "$FIX/x_y"
out=$(w x/y 2>&1); rc=$?
check "separate state per repo set"                 3 $rc "$out" "no earlier state"

# Review round 1 regressions.
rm -rf "$state"; printf '%s\n' "$pr1" > "$FIX/o_a"; printf '%s\n' "$pr2" > "$FIX/o_b"
out=$(w o/a, o/b 2>&1); rc=$?
check "list split by a space keeps every repo"      3 $rc "$out" "watching 2 open PRs in o/a o/b"
out=$(timeout 5 "$BASH" "$watch" o/a --interval 2>&1); rc=$?
check "option without its value is a usage error"  1 $rc "$out"
out=$("$BASH" "$watch" --help 2>&1); rc=$?
check "help lists exit 4"                           0 $rc "$out" "five polls in a row failed"
out=$(PR_WATCH_MAX_POLLS='' "$BASH" "$watch" --interval 0 --state-dir "$state" o/a 2>&1); rc=$?
check "interval below 10 s refused outside tests"  1 $rc "$out" "at least 10"
PR_WATCH_MAX_POLLS=99 "$BASH" "$watch" --interval 30 --state-dir "$state" o/a,o/b >/dev/null 2>&1 & spid=$!
sleep 1
out=$(w o/a,o/b 2>&1); rc=$?
check "second watcher on the same repos refused"   1 $rc "$out" "already running"
kill $spid 2>/dev/null; wait $spid 2>/dev/null
mkdir -p "$state/o_a+o_b.lock"; echo 999999 > "$state/o_a+o_b.lock/pid"
out=$(w o/a,o/b 2>&1); rc=$?
check "stale lock (dead pid) is taken over"         3 $rc "$out" "watching 2 open PRs"
[ ! -d "$state/o_a+o_b.lock" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: lock released on exit"; }

# Review round 2 regressions.
out=$(w --state-dir --handled o/a 2>&1); rc=$?
check "option value that is a flag is refused"     1 $rc "$out" "needs a value"
mkdir -p "$state/o_a+o_b.lock"
out=$(w o/a,o/b 2>&1); rc=$?
check "fresh lock without a pid is held"            1 $rc "$out" "already running"
touch -t 202001010000 "$state/o_a+o_b.lock"
out=$(w o/a,o/b 2>&1); rc=$?
check "old lock without a pid is taken over"        3 $rc "$out" "watching"
sleep 300 >/dev/null 2>&1 & spid=$!
mkdir "$state/o_a+o_b.lock" && echo $spid > "$state/o_a+o_b.lock/pid"
out=$(w o/a,o/b 2>&1); rc=$?
check "lock held by a pid that isn't pr-watch is stale" 3 $rc "$out" "watching"
kill $spid 2>/dev/null; wait $spid 2>/dev/null
PR_WATCH_MAX_POLLS=99 "$BASH" "$watch" --interval 30 --state-dir "$state" o/a,o/b >/dev/null 2>&1 & wpid=$!
sleep 1; t0=$(date +%s); kill -TERM $wpid; wait $wpid 2>/dev/null; t1=$(date +%s)
[ $((t1 - t0)) -le 3 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: TERM during sleep took $((t1 - t0)) s"; }
[ ! -d "$state/o_a+o_b.lock" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: lock left after TERM"; }

echo "passed: $pass, failed: $fail"
[ "$fail" = 0 ]
