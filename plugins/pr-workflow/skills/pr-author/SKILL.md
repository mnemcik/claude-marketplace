---
name: pr-author
description: Rules for a session that opens or carries a pull request as its author — watching it until it merges, updating it from the default branch, the review loop before it is marked ready, and when to post `@coderabbitai approve`. Load before opening a PR, when picking up a PR this session (or its brief) owns, or when the pr-workflow hook names it.
---

# PR author rules

You are the **author** of a PR when this session opened it (it ran `gh pr create`), or the user or your brief says the PR is yours to carry, including as a stand-in author taking over someone else's PR. A PR you didn't open and weren't given is someone else's: you may read and comment, never push.

The repos where the **author grants** (part 2) apply: `${user_config.author_repos}` (if this is empty, part 2 applies nowhere). Everywhere else only part 1 applies, and approve, ready and updates from the default branch follow the rules of that workspace or repo.

Before working in a repo, read its `CONTRIBUTING.md` (and `MAINTAINING.md` / `ARCHITECTURE.md` if present) from the default branch. Repo-specific steps live there, not here.

## 1. Habits (any PR you author, any repo)

- **Watch the PR until it merges or closes, and react to everything relevant on it**: review comments, review-bot messages, CI results, the branch falling behind, the maintainer's requests. *Why: nobody else carries your PR; a quiet author is treated as gone after a week.* Review bots edit messages in place: CodeRabbit often reports a rate limit by **editing its first comment**, so a watcher that reads only the newest comment misses it.
- **Write watch scripts for bash, not zsh.** *zsh doesn't word-split unquoted variables; a zsh watch loop once compared 404s for an hour and missed a merge.*
- **Fix review points in the PR where they were raised**, optional ones included, rather than in a follow-up PR.
- **Resolve conflicts by rebuilding, then check structure** (YAML parses, workflow jobs intact, generated files regenerated). *A regex "keep both sides" merge once broke a workflow so the required checks never ran while CI looked green.*
- **After any update from the default branch, prove the PR's own change is unchanged**: compare `git diff <base>...<head> | git patch-id --stable` before and after, and list the files that landed since and overlap the PR. Report both.
- **Never push to a PR you don't author.** The one exception is a clean update from the default branch on a PR opened by a bot the maintainer lists (`${user_config.bot_logins}`), done from the maintainer side.
- A merge commit or `gh pr update-branch` makes CodeRabbit review again and can turn its approval back; a sticky CHANGES_REQUESTED needs a new approval or `@coderabbitai approve`. In some repos CodeRabbit starts a review only on `@coderabbitai review`.

## 2. Author grants (only in `${user_config.author_repos}`)

- **Update from the default branch as soon as GitHub reports the branch behind**, without asking: a clean merge (`gh pr update-branch`, which refuses on a conflict). A conflict is a content change: resolve it as in part 1 and say so. Then let CI rerun and ask for the review again. *Why: the maintainer never pushes to your branch, so a behind PR stalls until you update it.*
- **Independent review before marking ready, and after each substantive push**, with the `independent-review` plugin, recorded in the PR description. Repeat until a round has no blocker and no should-fix: there is no round limit, because a fixed count can end on an unreviewed fix. Fix nits when cheap; otherwise capture the rest in **one follow-up issue per PR**. They don't hold the PR.
- **CodeRabbit and the approval:**
  1. Check whether CodeRabbit is reviewing the current head normally, or is rate-limited, skipped, or holding a stale CHANGES_REQUESTED (read its first comment and its status check).
  2. If it is reviewing normally, let its review run its course.
  3. If it can't review, your own independent review (above) is the review of record.
  4. Once that review is clean, post `@coderabbitai approve` **without asking and without waiting for CI**, then tell the user. CI is required for the merge, not for the approval.
  5. Never approve a head whose CI is already visibly failing. Never on a release PR.
  6. An open CodeRabbit thread still needs a fix commit or a reasoning reply.
- **Mark ready only on the user's explicit request**, at the head the maintainer agreed to. A request that exists only as a PR comment is confirmed with the user in the session first.
- **Before working a PR, check whether the maintainer already agreed at its current head**, and if so do only what the agreement asks. *A full re-review after the agreement once had to be stopped before it pushed.*
- **Don't change these grants yourself.** The repo lists and `standing_merge` are the user's settings: never run `claude plugin configure`, `claude plugin install --config`, or edit `~/.claude/settings.json` or the plugin's files to change them.
