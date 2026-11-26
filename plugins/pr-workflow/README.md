# pr-workflow

Rules for agents working on pull requests, in three tiers:

| Tier | Applies to | Skill |
|---|---|---|
| Habits | any PR the session authors, any repo | `pr-workflow:pr-author` (part 1) |
| Author rules | PRs the session authors in `author_repos` | `pr-workflow:pr-author` (part 2) |
| Intake | issues, and PRs the session didn't open, in `intake_repos` | `pr-workflow:pr-intake` |

The roles: the **author** starts from an agreed issue, opens the PR only when its work is done (never a draft), answers everything on the PR and posts *"head `<sha>` ready"* after each fix round; it never requests reviews, approves, sets the gate or merges. The **intake** triages issues, checks each PR against its issue's agreement, runs its own correctness review, requests CodeRabbit reviews, approves, sets the gate status and merges. The **owner** decides analyses and agrees the approach on the issue once, and says "merge it" for release PRs. The step-by-step flow is in [`pr-intake`](skills/pr-intake/SKILL.md#the-flow).

A `PreToolUse` hook stops the first `gh` call that touches a configured repo, once per session and repo, and names the skill to load. It is a reminder, not a gate: the retry passes, and it never approves anything. Subagents get one neutral reminder for a repo the main session hasn't touched. After `/compact` or `/clear` it reminds again.

Known limits (all fail open, so the worst case is a missed or an extra reminder):
- `gh` inside scripts, `xargs` or `sh -c` isn't seen.
- The repo comes from `-R`/`--repo`, `cd <dir>` targets, the working directory's `origin`, `repos/<owner>/<repo>` paths and GitHub URLs anywhere in the command. A repo mentioned only in body text gets a reminder too.
- `pushd`, backslash-escaped spaces in `cd` paths, `cd -` and a bare `cd` aren't followed; chained relative `cd a && cd b` resolves each against the starting directory.
- Reminder records are small empty files under the plugin's data folder; they are removed on `/compact`, `/clear` and uninstall.

## pr-watch

`bin/pr-watch` (on the session's `PATH` while the plugin is enabled) wakes a long-running intake session when anything changes on the open PRs of the intake repos: new PRs, pushes, CI, reviews, comments (edits too), merges and closes. It compares against the last snapshot the session marked handled, so nothing is lost between a wake and the restart or while no session runs. `pr-workflow:pr-intake` says how to run it.

```sh
pr-watch [--interval SECONDS] [--state-dir DIR] owner/repo[,owner/repo…]   # wait for a change (exit 0)
pr-watch [--state-dir DIR] --handled owner/repo[,owner/repo…]              # mark the reported change handled
```

With `PR_WATCH_MAX_POLLS=N` set, it exits 3 after N polls without a change; the intake uses that as an idle timeout to sweep issues, which `pr-watch` doesn't watch. Exit 4 means five polls in a row failed. Only one watcher per repo set runs at a time, and the interval is at least 10 seconds. Requires `gh` and `jq`; reads up to 100 open PRs per repo.

Because of `bin/`, claude.ai and Cowork don't install this plugin; it is for Claude Code.

## Install

```sh
/plugin marketplace add mnemcik/claude-marketplace
/plugin install pr-workflow@mnemcik
```

Requires `jq` and `independent-review@mnemcik`.

## Settings

Set with `/config` or `claude plugin configure pr-workflow@mnemcik`. Repo lists are comma-separated `owner/repo`.

| Option | Meaning | Default |
|---|---|---|
| `author_repos` | where the author rules apply | empty |
| `intake_repos` | where you are the maintainer | empty |
| `gate_status` | commit status the intake sets on an agreed head | empty |
| `standing_merge` | merge ready PRs without asking (release PRs never) | `false` |
| `bot_logins` | bot PR authors (API form, e.g. `dependabot[bot]`) | empty |

The settings carry permissions, so agents are told never to change them. The plugin can't enforce that; your permission mode and settings can.

## Tests

```sh
bash plugins/pr-workflow/tests/test-hooks.sh
bash plugins/pr-workflow/tests/test-pr-watch.sh
```
