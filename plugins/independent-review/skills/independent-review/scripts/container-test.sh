#!/usr/bin/env bash
# Run a checkout's tests in a throwaway container, so the code under review never
# runs on the host. Used by the independent-review skill with `--tests container`.
#
# Usage: container-test.sh <checkout-dir> <image> <prepare-cmd> <test-cmd>
#
#   prepare-cmd  runs WITH network and a writable dependency cache, to fetch
#                dependencies. It must not execute the project's code (Go:
#                `go mod download`; npm: `npm ci --ignore-scripts`). Use "true" if
#                there is nothing to fetch.
#   test-cmd     runs with --network=none and the cache mounted read-only. Linters
#                that load project config or plugins go here too.
#
# The container gets only a snapshot copy of the checkout (a fresh git repo, no .git
# from the source) and a dependency cache volume: no home directory, credentials, SSH
# agent or host paths. It is removed afterwards, also on timeout or interrupt.
#
# Env: CT_TIMEOUT  seconds per phase (default 300; the skill's budget is 10 min total)
#      CT_CACHE_KEY  extra cache key, e.g. owner/repo (default: none; cache per image)
#      CT_CACHE_DIR  cache path inside the container (default /cache)
#      CT_ENV  extra `-e` pairs, space-separated, no globbing
set -euo pipefail

if [ $# -ne 4 ]; then
  echo "usage: $0 <checkout-dir> <image> <prepare-cmd> <test-cmd>" >&2
  exit 2
fi
src=$1 image=$2 prepare=$3 test=$4
timeout=${CT_TIMEOUT:-300}
cache=${CT_CACHE_DIR:-/cache}

if command -v podman >/dev/null 2>&1; then rt=podman
elif command -v docker >/dev/null 2>&1; then rt=docker
else echo "container-test: neither podman nor docker found" >&2; exit 3
fi
[ -d "$src" ] || { echo "container-test: no such checkout: $src" >&2; exit 2; }

hash() {
  if command -v shasum >/dev/null 2>&1; then shasum | cut -c1-12
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum | cut -c1-12
  else cksum | cut -d' ' -f1
  fi
}

name="ir-ct-$$-$RANDOM"
work=$(mktemp -d "${TMPDIR:-/tmp}/ir-container-test.XXXXXX")
cleanup() {
  "$rt" rm -f "$name" >/dev/null 2>&1 || true
  rm -rf "$work" ${nohome:+"$nohome"} || true
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# A snapshot copy, so nothing the tests write lands in the reviewed checkout. Tests
# often call git, so the copy is a fresh repository. Host git runs with no global or
# system config (no filter drivers, signing or hooks the checkout's .gitattributes
# could reach), so none of the project's code runs on the host. Symlinks are copied
# as symlinks, not followed.
(cd "$src" && tar --exclude=./.git -cf - .) | (cd "$work" && tar -xf -)
nohome=$(mktemp -d "${TMPDIR:-/tmp}/ir-container-nohome.XXXXXX")
hostgit() {
  # HOME and XDG_CONFIG_HOME too: git older than 2.32 ignores GIT_CONFIG_GLOBAL.
  HOME="$nohome" XDG_CONFIG_HOME="$nohome" \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C "$work" \
    -c core.hooksPath=/dev/null -c commit.gpgsign=false \
    -c user.name=snapshot -c user.email=snapshot@invalid "$@"
}
hostgit init -q
hostgit add -A
hostgit commit -q --no-verify -m snapshot

vol="ir-cache-$(printf '%s|%s' "$image" "${CT_CACHE_KEY:-}" | hash)"
"$rt" volume inspect "$vol" >/dev/null 2>&1 || "$rt" volume create "$vol" >/dev/null

common=(--rm --name "$name" --cap-drop=ALL --security-opt=no-new-privileges
  --pids-limit=1024 --memory=4g -w /src -v "$work:/src"
  -e HOME=/tmp -e GOMODCACHE="$cache/gomod" -e GOCACHE=/tmp/gocache
  -e GOFLAGS=-buildvcs=false -e GOTOOLCHAIN=local -e npm_config_cache="$cache/npm")
set -f
for kv in ${CT_ENV:-}; do common+=(-e "$kv"); done
set +f

# Runs one phase with a wall-clock limit enforced here (works for docker and podman):
# on timeout the container is removed, not just the client killed.
phase() {
  "$rt" run "$@" &
  local pid=$! waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge "$timeout" ]; then
      echo "container-test: timed out after ${timeout}s" >&2
      # The container may not exist yet (slow pull or create): stop the client
      # too, then remove the container again in case it appeared meanwhile.
      "$rt" rm -f "$name" >/dev/null 2>&1 || true
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      "$rt" rm -f "$name" >/dev/null 2>&1 || true
      return 124
    fi
    sleep 1
    waited=$((waited + 1))
  done
  wait "$pid"
}

echo "== prepare (network on, project code must not run): $prepare"
phase "${common[@]}" -v "$vol:$cache" "$image" sh -c "$prepare"

echo "== test (network off, cache read-only): $test"
set +e
phase "${common[@]}" --network=none -v "$vol:$cache:ro" "$image" sh -c "$test"
status=$?
set -e
echo "== exit $status"
exit $status
