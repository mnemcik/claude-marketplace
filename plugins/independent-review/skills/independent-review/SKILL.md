---
name: independent-review
description: Run an independent, fresh-context review of a PR, branch, commit range, uncommitted changes, design, analysis, recommendation, plan or document. It pins the exact version, briefs a read-only reviewer that never saw the conversation, validates every finding before acting, records what the review covered, and re-reviews the delta after fixes until a round is clean. Use when the user says "independent review", "spin off a reviewer", "review this design/PR/doc", "did we do our own review?", before reporting a PR ready to merge, before presenting a design or recommendation for approval, or when another skill needs a review step.
user-invocable: true
---

# Independent Review

A reviewer that has never seen the conversation, reading the exact version you're about to ship or present, through a brief that says what to check. Then every finding is validated before anything is done with it, and the record says what was covered.

**Why it exists:** a hand-written brief varies from review to review, and so does what it covers. Reviews of fix commits keep finding defects the fixes introduced. And the readiness report often doesn't say which commits a review covered.

## When to run it (and when to skip)

- **A PR, or a substantive push to one:** always. A push that only rewords text or comments needs no re-review.
- **A design, analysis, recommendation, plan or document,** before presenting it for approval: by default. **Skip only when the item is really straightforward**: one obvious answer, follows an existing pattern, trivially reversible. Say that no review ran, and why.

## Arguments

`/independent-review <target> [--baseline <path|url>] [--split-lenses] [--tests host|container|ci]`

| Target | Template |
|---|---|
| PR URL or number | code |
| branch, `A..B` / `A...B` range, commit | code |
| `uncommitted` (the current working tree) | code |
| path to a design, analysis, ADR, plan, recommendation | design |
| path to a guide, runbook, PRD, Jira text, message | document (`--baseline` for the original it replaces or summarises) |

If the type is ambiguous, say which template you picked and why. Only ask if the target itself is ambiguous.

**Where the code under review runs (`--tests`, code targets only):**

| Mode | What runs where |
|---|---|
| `host` (default) | Tests run in the detached checkout on this machine. |
| `container` | Nothing from the change runs on this machine. Dependency installs, tests and linters (many linters load project config or plugins) run only through `scripts/container-test.sh` (in this skill's directory), in a throwaway Podman or Docker container: a prepare command with network that must not run the project's code, then the test command with `--network=none` and the dependency cache read-only. The container gets only a snapshot copy of the checkout. Use it for code you don't trust, or when the caller or the workspace asks for it. |
| `ci` | No local runs. The results are the CI results **at the pinned SHA** (commands below), quoted in the brief as "tests: CI at <sha>". With none at that SHA (no PR, a branch or uncommitted target, fork workflows awaiting approval), write "tests not run: no CI at <sha>". |

`ci` mode reads both check runs and legacy commit statuses at the pinned SHA:

```bash
gh api --paginate "repos/<owner>/<repo>/commits/<sha>/check-runs?per_page=100" --jq '.check_runs[] | "\(.name): \(.conclusion // .status)"'
gh api "repos/<owner>/<repo>/commits/<sha>/status" --jq '.statuses[] | "\(.context): \(.state)"'
```

Prepare commands known not to run project code: Go `go mod download`; npm `npm ci --ignore-scripts`. For other ecosystems, if no such fetch step is known, use `true` and run the tests offline, or write "tests not run: <why>". Set `CT_CACHE_KEY=<owner/repo>` so the writable cache isn't shared across repos. Each phase is limited by `CT_TIMEOUT` (default 300 s), so both fit the 10-minute budget.

If the workspace or a caller names a mode for this repo, use it. Never fall back to `host` from `container` or `ci`: if the container runtime is missing or the run fails to start, write "tests not run: <why>".

**Caller mode.** When another skill runs this one (for example the analysis skill's review step), follow the same steps, but **don't edit the caller's target and don't write the record into it.** Return the result described in [Caller contract](#caller-contract). The PR review loop is *not* a caller: on a PR, this skill pushes its own fixes and keeps the record in the conversation (Step 5).

## Step 0 — Scope and pin

Pin the exact version **before** anything runs. Record it; every later statement refers to it.

**Code:**
1. **Find the repo.** A PR in another repo uses its local clone (look in the usual clone location first). If there is none, ask once whether to clone it.
2. **Pin the head and the base.**
   - **PR:** `gh pr view <n> -R <owner/repo> --json headRefOid,headRefName,baseRefOid,baseRefName,title,body,isCrossRepository,author`. `-R <owner/repo>` is the base repo. Its **local remote** is the one whose URL in `git -C <repo> remote -v` matches `<owner/repo>` (it isn't always `origin`; in a fork clone it may be `upstream`). Fetch from it: `git -C <repo> fetch <base-remote> pull/<n>/head <baseRefName>`. If no remote matches, fetch by URL instead: `git -C <repo> fetch https://github.com/<owner/repo>.git pull/<n>/head <baseRefName>`. Then check that both SHAs resolve: `git -C <repo> cat-file -e <headRefOid>` and `git -C <repo> cat-file -e <baseRefOid>`. **If either can't be resolved, stop and say so.** Never review something else instead.
   - **Always pin both ends as SHAs:** head = `headRefOid`, base = `baseRefOid`. Never pin a branch name or the literal `HEAD`. A local `main` may be stale, and `HEAD` means something else inside the checkout.
   - **Branch or range:** resolve both ends to SHAs with `git rev-parse`. In a workspace with no remote, branches and ranges are already in the shared object store, so there's nothing to fetch.
   - **Uncommitted:** `snap=$(git stash create)`. Empty output means there are no tracked changes: pin the `HEAD` SHA (`git rev-parse HEAD`) and say so. Otherwise the version is `uncommitted snapshot <snap> of <HEAD-sha>`, and the **base is `<HEAD-sha>`**. List untracked files (`git ls-files --others --exclude-standard`). They are **not** in the snapshot, so the coverage block must say so unless they're staged first.

**File (design or document):** `git hash-object <path>` is the version, plus the commit that last touched it (`git log -1 --format=%h -- <path>`) and "uncommitted" if it is dirty. Save a snapshot copy to `<scratchpad>/independent-review/snapshots/<name>-<hash>`, so the next round can diff against it. **Snapshot each local source** the target cites the same way, because the doc reviewer can only read files and would otherwise check the live, possibly changed, source. Pin web sources by URL and the date read.

**Size check.** Propose `--split-lenses` (one reviewer per lens) when the target is large (a diff over about 1,500 changed lines, or a document over about 3,000 words) or high-stakes (architecture, security, data, money). State the cost, and only split if the user agrees.

## Step 1 — Brief

Read the template from this skill's directory: `templates/code.md`, `templates/design.md` or `templates/document.md`. Fill in every placeholder.

- **Claims to check:** take them **from the target itself** (the PR description, the document's statements), not from your memory of it.
- **Probes:** for this specific change, name the edge cases it could break and the other places that enumerate the same thing.
- **Word cap:** about 900 words for a first round, about 450 for a delta round.
- **Governing rules:** list the target repo's or workspace's rule files (`CLAUDE.md`, `CONTRIBUTING`, and any rule notes they point to that are relevant to the target).
- **File targets:** give the reviewer the **snapshot paths** from Step 0 (the target and its sources) as the things to read. The doc reviewer has no git, so this is the only way it sees the pinned version.
- **Delta rounds for file targets:** run the diff yourself (`diff -u <previous-snapshot> <new-snapshot>`), save it to `<scratchpad>/independent-review/snapshots/<name>-<old>-to-<new>.diff`, and give the reviewer that path. The doc reviewer can't run commands.
- **Never include** the conversation, your reasoning, or what you think the answer is.

## Step 2 — Run

**Code:**
1. **Clear leftovers.** Run `git -C <repo> worktree prune`, then remove any of *this session's* `<scratchpad>/independent-review/co-*` checkouts that no live run is using.
2. **Create a checkout for this run:** `git -C <repo> worktree add --detach <scratchpad>/independent-review/co-<sha7>-<runid> <sha>`. In `container` and `ci` modes, run it as `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C <repo> -c core.hooksPath=/dev/null worktree add …`: the checkout's `.gitattributes` then can't reach filter drivers from your global or system git config, and no `post-checkout` hook runs (a repo-relative `core.hooksPath`, as husky sets, would otherwise run the change's own hook). Needs git 2.32 or newer; on older git, use `ci` mode. Use `<runid>` = a short timestamp, so two runs never share a path.
3. **Run the tests first, yourself,** with the repo's documented commands (README, CONTRIBUTING, CLAUDE.md, CI workflow), in the mode chosen above: in that checkout (`host`); with `CT_CACHE_KEY=<owner/repo> scripts/container-test.sh <checkout> <image> <prepare> <test>` (`container`; the image from the repo's toolchain file, e.g. `docker.io/library/golang:<go directive>` from `go.mod`; installs only in `<prepare>`, linters only in `<test>`, never on the host); or from CI (`ci`). Install dependencies first if needed (in `container` mode: in the prepare command). **Budget: 10 minutes in total.** Put the results and the mode in the brief, and in `container` mode also the exact script command line, which is the only way the reviewer may re-run tests. If it doesn't finish within the budget, or needs credentials or a network that isn't there, write "tests not run: <why>".
4. **Start the reviewers in parallel, in the background:**
   - the Agent tool with `subagent_type: "independent-review:code-reviewer"` and the brief;
   - **only if the target is in the session's own repo** (the repo of the current working directory): the `code-review` skill with an explicit level and range, e.g. `high --max-findings 10 <base-sha>...<head-sha>`. Use the pinned SHAs, even for a PR: the PR number would review its current head, not the pinned one. For another repo, skip it and say "`/code-review` not run: other repo".
5. **Wait for every reviewer** before Step 3.
6. **Check what `/code-review` reviewed.** It doesn't print SHAs, and it names only the files it has findings for. **Every file it names must be inside `git diff --stat <base>...<head>`.** If any isn't, or it returned nothing, count it as "didn't run". If it names only some of the changed files, record "full-range coverage not confirmed".
7. **Remove the checkout, always**, even if a reviewer failed or stalled: `git -C <repo> worktree remove --force <path>`, then `git -C <repo> worktree prune`.

**File:** start the Agent tool with `subagent_type: "independent-review:doc-reviewer"` and the brief, in the background, and wait for it. With `--split-lenses`, start one reviewer per lens, each with the same brief narrowed to its lens.

**Auto mode:** the doc reviewer's WebFetch and WebSearch calls may raise permission prompts in this session. Suggest allowing them for the session if they stall.

## Step 3 — Validate and sort

**Re-check every finding against the source before acting on it.** Reviewers are wrong in recognisable ways:
- a grep that missed matches in another encoding;
- reading a stale branch;
- a quoted line that isn't in the file;
- a miscount.

Drop the findings that fail, and keep a one-line reason for each.

Sort what's left:
- **Findings:**
  - **fix**: small, clear, reversible;
  - **owner's decision**: changes scope or design, or is a judgement call; listed, never applied;
  - **rejected**: with the reason.
- **Builder questions:**
  - **already answered**: point to where;
  - **minor**: settle it yourself and mark it as your call;
  - **owner's**.

## Step 4 — Apply (stand-alone only)

- Apply the **fix** pile.
- Each code fix gets a **regression test that fails without the fix**, run in the same `--tests` mode as the review (in `ci` mode: push the test first and see it fail in CI, then the fix).
- **"A PR you opened"** means a PR opened in this session, or one the user has said is theirs for you to change. Anything else, including PRs by the user's own account that they opened by hand, is treated as **someone else's PR**: no commits, no pushes, no description edits.
- **A PR you opened:** before committing, check that the local clone is on the PR's `headRefName` and at the pinned head SHA. If it isn't, stop and say so. Then commit, and push the fixes to the branch's upstream. For a PR whose head is in a fork (`isCrossRepository`), that is the head repo's remote, not the base remote from Step 0. If a fix makes the description inaccurate, correct what it says about the change, but never add the review record or a "changed after review" section to it (Step 5).
- **Branch or range targets:** commit fixes only on the session's own branch, never on someone else's.
- **Never merge.** Merging needs the user's explicit per-action authorisation.
- In caller mode, skip this step.

## Step 5 — Record

Write one coverage block per round:

```
**Review <N>** — <target> @ <version> (base <base>) · <YYYY-MM-DD>
- Reviewers: <code-reviewer | doc-reviewer> (<lenses>)[; /code-review <level> | /code-review not run: <why>]
- Tests (<host | container | ci>): <command → result> | not run: <why>
- Findings: <b> blocker, <s> should-fix, <n> nit → fixed: <…> (in <sha>); owner's: <…>; rejected: <…> (<reason>); dropped in validation: <…> (<reason>)
- Builder questions: <a> answered, <m> minor (my call: <…>), <o> owner's: <…>
- Verified true: <…>
- Not verified: <…>
```

Where it goes:
- **Any PR, yours or someone else's:** never in the PR description. The maintainer side runs its own review and doesn't rely on an author-written record, and the description becomes the squash commit message, so a record there would also end up in the repo's history. Keep the record in the conversation, after that round's fixes are pushed, and in a review file if the workspace has a place for one. In caller mode, return it to the caller for its own record. Never edit someone else's description, and comment on a PR only when the user asks.
- **A design or document in a Consigliere workspace:** in the target's own `## Review` section, unless in caller mode (the caller writes it). Never add a `## Review` section to a file in someone else's repo.
- **A large multi-reviewer review:** a separate `review-<topic>-<YYYY-MM-DD>.md` next to the target, linked from it.
- **Consigliere workspace** (a `.cg.json` at the workspace root): also add a line to the session project's `log.md`, even when the PR is in another repo.
- **Elsewhere, for a file target:** ask once where review records go in this repo.

## Step 6 — Delta re-review

After any substantive fix, run Steps 0–5 again on the new version, with the brief's delta block:
- **Scope:**
  - code: `git diff <previous> <new>` (for snapshots, a plain `git diff` between the two snapshot SHAs, never a `..` range);
  - files: the diff against the stored snapshot.
- **Regression check:** each earlier finding is really fixed, not just claimed.
- **Lighter:** delta rounds run our reviewer only. Add `/code-review` again only if the delta changes logic (not just text, comments or tests).

A round is **clean** when it has no blocker and no should-fix (counting the findings that survived validation and weren't rejected). Nits may remain. Open owner's builder questions don't stop a round being clean, but they are always reported.

**Repeat until a round is clean. There is no round limit by default.** Two things end the loop without a clean round, and neither is reported as a finished review:
- **Only owner's decisions are left:** every remaining blocker or should-fix is in the owner's pile, so there is nothing to fix and re-review. Report "review open: waiting on the owner", list what's open, and hand it to the user.
- **A caller's round limit:** only a caller can set one (see [Caller contract](#caller-contract)); stand-alone runs have none. If the round at the limit still has a blocker or should-fix, return `stopped: unresolved` with what's open.

## Step 7 — Report

Any readiness or approval message states coverage in one line:

> Reviews cover `<version>` (head); not verified: <…>.

If the head isn't covered (a fix commit after the last round, for example), say so and run the delta round before calling it ready. Don't call it ready while the last round has an open blocker or should-fix. For a PR, this message goes in the conversation, not in the PR description (Step 5).

## Caller contract

**Inputs from the caller** (needed from round 2 on):
- the round number;
- the previous version and snapshot path;
- the earlier findings to regression-check.

Without these, the call is treated as round 1.

**Optional: a round limit** (`round limit: <n>`). Off by default: without it, the caller keeps calling for delta rounds until one comes back `clean`. With it, the limit counts the caller's round number, and the round at the limit returns `stopped: unresolved` if it still has a blocker or should-fix.

In caller mode, return exactly:
- **Outcome:** `clean` | `findings` | `stopped: unresolved` (only when the caller set a round limit and reached it)
- **Findings piles:** fix / owner's / rejected (each with location, failure scenario, suggested fix)
- **Builder-question piles:** answered / minor / owner's. **The owner's questions are returned even when the outcome is clean.**
- **The coverage block** (Step 5), for the caller's own record (its target, or wherever the caller keeps it; never a PR description).

The caller applies fixes to its own target, then runs this skill again for the delta round.

## Attribution

The builder check and the "declined to judge" list follow obra/superpowers (MIT). The claims check (narrative as testimony; falsify, then report what fails) follows BMAD-METHOD `bmad-review` (MIT). The per-finding validation pass follows Anthropic's `code-review` plugin (Apache-2.0). All are re-expressed here, not copied.
