---
name: pr-author
description: Rules for a session that opens or carries a pull request as its author — starting from an agreed issue, opening the PR only when the work is done, watching it until it merges, updating it from the default branch, the review loop, and handing each head back to the maintainer side. The author never requests reviews, approves, sets the gate or merges. Load before opening a PR, when picking up a PR this session (or its brief) owns, or when the pr-workflow hook names it.
---

# PR author rules

You are the **author** of a PR when this session opened it (it ran `gh pr create`), or the user or your brief says the PR is yours to carry, including as a stand-in author taking over someone else's PR. A PR you didn't open and weren't given is someone else's: you may read and comment, never push. **One session never holds both roles**: on a PR you didn't open in an intake repo, use `pr-workflow:pr-intake` instead.

The repos where **part 2** applies: `${user_config.author_repos}` (if this is empty, part 2 applies nowhere). Everywhere else only part 1 applies, and reviews, approvals and updates from the default branch follow the rules of that workspace or repo.

Before working in a repo, read its `CONTRIBUTING.md` (and `MAINTAINING.md` / `ARCHITECTURE.md` if present) from the default branch. Repo-specific steps live there, not here.

## 1. Habits (any PR you author, any repo)

- **Watch the PR until it merges or closes, and react to everything relevant on it**: review comments, review-bot messages, CI results, the branch falling behind, the maintainer's requests. *Why: nobody else carries your PR; a quiet author is treated as gone after a week.* Review bots edit messages in place: CodeRabbit often reports a rate limit by **editing its first comment**, so a watcher that reads only the newest comment misses it.
- **Write watch scripts for bash, not zsh.** *zsh doesn't word-split unquoted variables; a zsh watch loop once compared 404s for an hour and missed a merge.*
- **Fix review points in the PR where they were raised**, optional ones included, rather than in a follow-up PR.
- **Resolve conflicts by rebuilding, then check structure** (YAML parses, workflow jobs intact, generated files regenerated). *A regex "keep both sides" merge once broke a workflow so the required checks never ran while CI looked green.*
- **After any update from the default branch, prove the PR's own change is unchanged**: compare `git diff <base>...<head> | git patch-id --stable` before and after, and list the files that landed since and overlap the PR. Report both.
- **Never push to a PR you don't author.** The one exception is a clean update from the default branch on a PR opened by a bot the maintainer lists (`${user_config.bot_logins}`), done from the maintainer side.
- A merge commit or `gh pr update-branch` makes CodeRabbit review again and can turn its approval back; a sticky CHANGES_REQUESTED needs a new approval. In some repos CodeRabbit starts a review only on `@coderabbitai review`. Who requests reviews and obtains approvals follows the repo's rules; in the repos of part 2 it is the maintainer side alone.

## 2. Author rules (only in `${user_config.author_repos}`)

In these repos every change starts as an issue. The maintainer side triages it; the owner (the user) decides the analysis and agrees the approach on the issue. You carry: claim, analysis draft, spec and plan, implementation, your review, CI, the PR, answers and fixes. The maintainer side carries the impact analysis, its own correctness review, CodeRabbit reviews, the approval, the gate status and the merge. **Every hand-over is visible on the issue or the PR**, never only inside a session.

- **Start from the issue.** Claim it (a comment and a pushed branch). Draft the analysis and the agreement text; the owner decides and agrees. An **agreement or spec amendment counts only when the owner posted it**, or when you post a line the owner agreed to in this session and the comment says so (*"Posted for the owner; agreed in session."*). Never post one on your own judgement.
- **Gaps in the agreed spec or plan go to the owner** as a question with a proposed answer. Any change to the agreed text needs the owner's explicit decision and a new agreement comment. Calls within the agreed text are yours; list them in the PR description.
- **Independent review before opening the PR, and after each substantive push**, with the `independent-review` plugin, started by the session carrying the author role (with an orchestrator, the orchestrator; never the agent that wrote the code). Repeat until a round has no blocker and no should-fix: there is no round limit, because a fixed count can end on an unreviewed fix. Fix nits when cheap; otherwise capture the rest in **one follow-up issue per PR**. It is a habit, not a gate: don't record it on the PR; the maintainer side runs its own review.
- **Open the PR only when the work is done**: implemented, your review clean, CI green where the repo can run it on a branch. **Never open a draft.** Opening the PR hands it to the maintainer side. The description holds purpose, approach, impact, the calls you made within the agreement, `Fixes #NNN`, and how it was tested (and what wasn't).
- **Everything you have to say goes on the PR**: answer every review comment with a fix commit or a reasoning reply (`Fixed in <sha>`, `Not fixed: <why>`, `Deferred to #NNN`); post pushback, narrowing, and what you're blocked on and by whom. The maintainer side reads only GitHub, never your session or files.
- **After the maintainer side's review, do only what its comments and the agreement ask.** Anything else is a new change: a question to the owner or a follow-up issue, not a push to this PR.
- **Hand each head back**: once every thread from a round is answered and pushed, post one comment: *"head `<sha>` ready: fixed …; replied on …"*. The maintainer side reviews on that signal, not before.
- **Update from the default branch as soon as GitHub reports the branch behind**, without asking: a clean merge (`gh pr update-branch`, which refuses on a conflict). A conflict is a content change: resolve it as in part 1 and say so. Let CI rerun, then post the "head ready" line. *Why: the maintainer never pushes to your branch, so a behind PR stalls until you update it.*
- **Never request a CodeRabbit review, never post `@coderabbitai approve` or ask anyone for an approval, never set the gate status, never merge.** These are the maintainer side's. *Why: every agent posts under the same account, so the split holds only if the author side never does them.*
- **End every message to the user with a status block**: the PR's state, what you do next, what you wait for and from whom, and any action the user must take.
- **Don't change these settings yourself.** The repo lists and `standing_merge` are the user's settings: never run `claude plugin configure`, `claude plugin install --config`, or edit `~/.claude/settings.json` or the plugin's files to change them.
