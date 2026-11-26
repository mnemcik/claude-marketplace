# Changelog

All notable changes to plugins in this marketplace are documented here, per plugin, newest first. Each entry links to the commit (or PR, for earlier history) where the change landed. Loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions use [SemVer](https://semver.org/).

**Convention:** every version-bump commit must add an entry here under the relevant plugin section. If a change is not worth a changelog line, it is not worth a version bump. This is a personal marketplace — commits land directly on `main`, no PR required.

**Version sources must stay in lockstep.** A plugin's version lives in three files: `plugins/<plugin>/.../plugin.json`, the `plugins[]` entry in `.claude-plugin/marketplace.json`, and this file's section for that plugin. Every version-bump commit must update all three — see [CLAUDE.md](CLAUDE.md) for the full rule and checklist.

---

## marketplace (manifest-level housekeeping)

### 2.1.0 — 2026-11-17 — pr-workflow added

- **Added:** the `pr-workflow` plugin to `plugins[]`. Top-level `version` bumped `2.0.0 → 2.1.0` for the manifest shape change.

### 2.0.0 — 2026-11-17 — moved to `mnemcik/claude-marketplace`

- **Moved:** the marketplace now lives in `mnemcik/claude-marketplace`, and its name is `mnemcik` (was `mnemcik-plugin-marketplace`, in an earlier repo). Plugins install as `<plugin>@mnemcik`. Plugin files copied at their current versions; their earlier git history stays in the old repo.

### 1.5.0 — 2026-11-15 — analysis added

- **Added:** the `analysis` plugin to `plugins[]`. Top-level `version` bumped `1.4.0 → 1.5.0` for the manifest shape change.

### 1.4.0 — 2026-11-14 — independent-review added

- **Added:** the `independent-review` plugin to `plugins[]`. Top-level `version` bumped `1.3.0 → 1.4.0` for the manifest shape change.

### 1.3.0 — 2026-10-02 — wrap removed

- **Removed:** the `wrap` entry from `plugins[]` in `.claude-plugin/marketplace.json`, and the `plugins/wrap/` directory. Top-level `version` bumped `1.2.0 → 1.3.0` for the manifest shape change, per the policy in [CLAUDE.md](CLAUDE.md). See the wrap section below.

### 1.1.0 — 2026-04-23 — retroactive bump for wrap addition

- **Changed:** Top-level `.claude-plugin/marketplace.json` `version` bumped `1.0.0 → 1.1.0`. Retroactive minor bump reflecting the manifest shape change when `wrap` was added to the marketplace (2026-04-16). Per the policy in [CLAUDE.md](CLAUDE.md), the top-level version tracks manifest shape changes (plugin added/removed, schema change), not individual plugin version bumps — so patch-level plugin releases since then (wrap 1.0.1 through 1.0.6, triage 1.0.1) did not warrant a top-level bump and do not now. Future plugin additions (e.g., MCP plugins) should bump the top-level minor.

### 2026-04-23 — reconcile wrap version in `marketplace.json`

- **Fixed:** `.claude-plugin/marketplace.json` `plugins[wrap].version` was stale at `1.0.4` while `plugins/wrap/.claude-plugin/plugin.json` had advanced to `1.0.5`. Updated the manifest entry to `1.0.5`. No plugin bump — this is a reconciliation of drift between the two files.
- **Added:** [`CLAUDE.md`](CLAUDE.md) at repo root documenting (a) the three-places rule for plugin versions, (b) a version-bump checklist, (c) SemVer guidance for skills, and (d) the policy for the top-level `marketplace.json` `version` field (bump on manifest shape change, not on every plugin bump).
- **Changed:** `README.md` → "Adding a New Plugin" updated to the newer `plugins/<plugin>/.claude-plugin/plugin.json` layout and extended with a "Releasing a New Version" checklist cross-linking to CLAUDE.md.

Motivation: wrap 1.0.3, 1.0.4, and 1.0.5 each shipped with at least one of the three version files out of sync. The checklist + CLAUDE.md rule prevent the next recurrence.

---

## analysis

### 0.3.1 — 2026-11-21 — public-release clean-up

- **Changed:** `authority:` check only where records carry it; install commands use `plugin@marketplace`.

### 0.3.0 — 2026-11-20 — review rounds until clean

- **Changed:** step 5 calls `independent-review` for delta rounds until a round comes back `clean`, with no round limit (the round-3 stop is gone, matching independent-review 0.3.0). When only owner's findings are left, it continues to step 6 with them listed. A last round that isn't `clean` forces "needs clarification" (was: a `stopped: unresolved` outcome).
- **Requires:** independent-review 0.3.0 or newer. ([#9](https://github.com/mnemcik/claude-marketplace/issues/9))

### 0.2.0 — 2026-11-20 — recon checks the environment's own tooling

- **Changed:** step 1 (Recon) names the environment's own tooling as an internal source: installed plugins and skills, the framework and its extensions, and the owner's own plugin and extension repos.
- **Added:** recon records what it checked and what each source turned up, so a miss shows in the analysis. The template's Current state gets a `Recon checked` line; a short analysis states it in one line in step 6. ([#10](https://github.com/mnemcik/claude-marketplace/issues/10))

### 0.1.0 — 2026-11-15 — first release

- **Added:** the `/analysis` skill (`analysis:analysis`): picks up one backlog item (idea file, GitHub or Jira issue, pasted problem) with a decision-ready analysis.
  - **Process:** intake → recon and validity check (always run: does the problem exist, is the expectation right, is it current, is it the right problem) → framing check → cited evidence → one recommendation with 0–3 alternatives and a hidden-constraints check → independent review → present with every open decision and a verdict → record → propose a hand-off. It never implements.
  - **Sizes:** short (inline) and full (an analysis document from `templates/analysis.md`).
  - **Review:** runs `independent-review` in caller mode, with delta rounds until clean, stopping after round 3.
  - **Consigliere-aware:** detects a cg workspace by `.cg.json` from the item's location and writes to the project's files; elsewhere asks once per repo where to save.
- **Requires:** the `independent-review` plugin.

## independent-review

### 0.3.1 — 2026-11-21 — public-release clean-up

- **Changed:** no owner-specific clone location.

### 0.3.0 — 2026-11-20 — no round limit; no review record in PR descriptions

- **Changed:** delta rounds repeat until a round has no blocker and no should-fix. The round-3 stop is removed: there's no round limit by default, and only a caller can set one (`round limit: <n>`, which then returns `stopped: unresolved`). A loop where only owner's decisions are left ends as "review open: waiting on the owner", never as a finished review.
- **Changed:** for any PR, the review record stays out of the PR description (no more `## Changed after an independent review` section): it goes in the conversation, a workspace review file, or the caller's own record. The maintainer side runs its own review, and the description becomes the squash commit message.
- **Why minor:** both are removed behaviour, which would be a major bump at 1.x; the plugin is pre-1.0, where SemVer puts such changes in a minor bump.

### 0.2.0 — 2026-11-15 — `--tests host|container|ci`

- **Added:** `--tests` chooses where the code under review runs. `host` (default) is the 0.1.0 behaviour. `container` runs the tests through the new `scripts/container-test.sh` in a throwaway Podman or Docker container: a prepare step with network that must not run project code, then the tests with `--network=none`, the dependency cache read-only, all capabilities dropped, and only a copy of the checkout mounted. `ci` takes the results from the PR's CI checks and runs nothing locally. No fallback to `host` from either.
- **Changed:** Step 4's regression test for a fix runs in the same mode; the coverage block names the mode; the code brief carries it.
- **Changed:** `code-reviewer` may re-run tests in `container` mode only through the script command line in its brief, and in `ci` mode runs nothing from the checkout.
- **Security notes:** in `container` mode the host-side snapshot and the review checkout run git with no global or system config (no filter drivers, signing or hooks reachable from the checkout's `.gitattributes`), installs and linters run only in the container, the timeout is enforced by the script for both runtimes and removes the container, and the writable cache is keyed per image and `CT_CACHE_KEY`. `ci` mode reads check runs at the pinned SHA, not the PR's current head.

### 0.1.0 — 2026-11-14 — first release

- **Added:** the `/independent-review` skill (`independent-review:independent-review`).
  - **Targets:** PRs, branches, commit ranges, uncommitted changes, designs, analyses, recommendations, plans and documents.
  - **Process:** pins the exact version (SHA, stash snapshot or content hash plus snapshot), then briefs a fresh-context reviewer from one of three templates (code, design, document). Every finding is validated before acting, and fixes and builder questions are sorted into piles. A coverage block is recorded per round. Delta rounds re-review only what changed, with a regression check, until a round has no blocker or should-fix, and it stops after round 3.
  - **Caller mode:** another skill can run it and get the result back, without its target being edited.
- **Added:** two agents.
  - `doc-reviewer`: read-only by its tool list (Read, Grep, Glob, WebFetch, WebSearch).
  - `code-reviewer`: runs in a detached checkout per run at the pinned commit, which is removed afterwards. Tests run first, within a 10-minute budget. For targets in the session's own repo, the built-in `/code-review` runs alongside as a second opinion.
- **Validated** on three earlier hand-reviewed targets: a design, a PR's first commit, and a runbook rewrite checked against its original.
- **Attribution:** the builder check and the "declined to judge" list follow obra/superpowers (MIT); the claims check follows BMAD-METHOD `bmad-review` (MIT); the per-finding validation pass follows Anthropic's `code-review` plugin (Apache-2.0). All are re-expressed, not copied.

## wrap

### Removed — 2026-10-02

- **Removed** from the marketplace after the migration window that started with 1.3.1 (2026-06-18). `wrap` ships with consigliere: `cg init` installs it into `.claude/skills/wrap/`, and since [v1.21.0](https://github.com/mnemcik/consigliere/releases/tag/v1.21.0) `cg sync --apply` keeps it current. Anyone who still has `wrap@mnemcik-plugin-marketplace` installed should uninstall it (`/plugin uninstall wrap@mnemcik-plugin-marketplace`) and run `cg init` in their workspace. 1.3.1 is the last marketplace release.

### 1.3.1 — 2026-06-18 — deprecated; wrap now ships with consigliere

- **Deprecated:** This marketplace plugin is superseded. As of **consigliere `cg` v1.11.0** the `wrap` skill ships embedded in the `cg` binary and is installed automatically by `cg init` into `.claude/skills/wrap/SKILL.md` (consigliere PR [#72](https://github.com/mnemcik/consigliere/pull/72), released in [v1.11.0](https://github.com/mnemcik/consigliere/releases/tag/v1.11.0)). Wrap hard-depends on consigliere framework concepts (`projects/`, `notes/`, `insights/`, the session-context badge, worktree isolation, the landing script), so co-shipping it with the framework removes the drift risk and the separate install step. consigliere bundles slash commands into `cg init` the same way.
- **Changed:** Added a deprecation banner at the top of `SKILL.md` prose and a `[DEPRECATED …]` prefix to the plugin `description` in both `plugins/wrap/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, pointing users at consigliere. No skill behaviour change — the wrap phases are unchanged.
- **Patch bump rationale:** doc-only change (deprecation banner + description text); no phase, capability, or behaviour was added or removed, so per the SemVer guidance in [CLAUDE.md](CLAUDE.md) this is a patch, not a minor. The top-level `marketplace.json` `version` is unchanged — the plugin remains listed (not yet removed), so the manifest shape has not changed. Tombstone/removal will be a separate later commit after a migration window.

### 1.3.0 — 2026-04-29

- **Added:** Pause mode. `/wrap pause` (or pause phrasing — "pause this", "pausing for now", "save state", "save my place") runs phases 1–6 identically, adds new **Phase 6.5** which writes `projects/<slug>/resume.md` from `templates/project/resume.md` capturing the in-flight cursor (active todo, current files, mental context, next concrete action, blockers), then diverges in Phase 7–9: WIP commit (`WIP pause: <one-line>`) + push branch to `origin/session/<slug>` (no land to `main`), Phase 8 skips worktree removal (worktree + branch are the resume vehicle), Phase 9 marker is `⏸️ Session paused — resume by re-entering project (worktree at <path>) or via /resume <slug>.` and the dirty flag stays set.
- **Added:** "Mode" section near the top of `SKILL.md` with a comparison table (end vs pause) and explicit detection rules. Default is end mode; pause is opt-in. Ambiguous wraps (uncommitted in-flight changes + no explicit signal) trigger a one-shot ask before proceeding.
- **Added:** "Pause from the main workspace is invalid" guardrail in Important behaviors — pause needs a `session/<slug>` worktree (the resume vehicle).
- **Changed:** Phase 7 step 6 (commit message) and step 7 (push) and step 8 (verify reachability) now branch on mode. End mode lands to `main` via the workspace's landing wrapper; pause mode pushes the branch to `origin/session/<slug>` as a remote backup. The `merge-base --is-ancestor` assertion targets `origin/main` in end mode and `origin/session/<slug>` in pause mode — same defense-in-depth, different ref.
- **Changed:** Phase 9 summary, dirty-flag handling, and terminal marker now have explicit end-mode and pause-mode variants.
- **Minor bump rationale:** new mode added without removing any prior behavior. End-mode wraps continue to behave exactly as in 1.2.0 — the new code paths only fire on explicit pause signals.

### 1.1.0 — 2026-04-24

- **Changed:** Phase 7 rewritten for the owner's workspace's ephemeral-branch-worktree model (landed 2026-04-24). Step 1 drops the meta-framework exception text and points at the workspace's idempotent create-worktree wrapper (e.g., `scripts/create-session-worktree.sh <slug>`). Step 7 prefers the workspace's landing wrapper (`scripts/land-worktree-commit.sh`) when present, falling back to direct push / PR flow otherwise. Step 8 retained as a defense-in-depth assertion with explicit rationale for why it is kept despite being tautological under the new branch-based model (trust boundary between wrap and whatever performed the push; catches silent-no-op pushes, crashed wrappers, and user-side detach mistakes). Motivating-incidents paragraph updated with the full 2026-04-20 → 2026-04-24 chain and the structural resolution.
- **Changed:** Phase 8 (Cleanup check → Worktrees) now prefers the workspace's removal wrapper (e.g., `scripts/remove-session-worktree.sh <slug>`) which atomically removes the worktree and its `session/<slug>` branch (refusing if the branch has unlanded commits), with a fallback to manual `git worktree remove` + branch cleanup.
- **Minor bump rationale:** new behavior (invoke workspace-specific wrappers when present, new defense-in-depth rationale added to step 8) added without removing any prior behavior. The `<sha>` arg to the landing script remains optional, so this skill continues to work against workspaces on the older detached-HEAD landing script interface.

### 1.0.6 — 2026-04-23

- **Fixed:** Phase 4 (Capture insights) now points at `insights/INDEX.md` instead of the legacy `insights/DRAFTS.md` filename. The workspace's rename landed on 2026-04-21; the skill had been silently telling Claude to read and write a file that no longer existed. Two references updated in `SKILL.md` (the read-for-duplicates step and the add-a-row step).

### 1.0.5 — 2026-04-22

- **Added:** Phase 7 step 8 — after pushing, assert the wrap commit is reachable from `origin/main` via `git merge-base --is-ancestor <wrap-sha> origin/main`. If the assertion fails, the skill surfaces recovery steps (fast-forward `main` from the main working tree, push, re-point the worktree's detached HEAD) instead of reporting a green wrap. Producer-side guard for the orphan-commit failure mode documented in the owner's workspace notes; discovered 2026-04-22 when a previous session's wrap commit was found orphaned and recovered by cherry-pick.
- **Fixed (housekeeping):** `plugin.json` version bumped from stale `1.0.2` to `1.0.5` — the 1.0.3 and 1.0.4 commits updated `SKILL.md` and `CHANGELOG.md` but left `plugin.json` behind.

### 1.0.4 — 2026-04-21

- **Added:** Terminal completion marker — the skill now ends with a distinctive final line (`✅ Wrap complete — session can be closed.`) so the user can tell at a glance whether the skill ran to the end or exited partway. Documented as the last output of Phase 9.
- **Added:** Phase 9 now clears the session-dirty flag in workspaces that use one (`.claude/session-context/<session_id>.json` with a `dirty` field). Pairs with a `PostToolUse` hook on the workspace side that sets the flag whenever Claude performs a file-mutating tool call — the status line reads the flag and renders a red `●` next to the area/project badge, so the user has a live "unwrapped work" indicator. Skipped silently for workspaces that don't use the flag.

### 1.0.3 — 2026-04-21

- **Added:** Phase 8 "Cleanup check" — prompts the skill to surface transient artifacts accumulated during the session before closing: worktrees for projects now `done`, local branches whose PRs have merged (via `gh pr view`), gitignored scratch directories, and still-running background processes. Every destructive action requires explicit user confirmation; nothing auto-kills or auto-removes. Existing Phase 8 (Summary) renumbered to Phase 9, with a `Cleanup:` line added to its example output.

### 1.0.2 — 2026-04-20

- **Fixed:** Phase 7 can no longer commit parallel-session work when two Claude sessions share the main workspace's git index. Added a worktree gate (step 1: abort staging if cwd is the main workspace and the workspace mandates per-session worktrees) and a staged-set verification step (step 5: `git status --short` after staging to catch extras that landed in the index between `git add` and `git commit`).
- **Changed:** Added a matching bullet to "Important behaviors" covering worktree isolation.

### 1.0.1 — 2026-04-20

- **Fixed:** Phase 7 previously instructed *"Stage all changed files in the workspace"*, which swept pre-existing uncommitted work from other sessions into wrap commits. Rewrote Phase 7 to stage only session-touched files by name, require a `git status` check first, forbid `git add -A` / `git add .` / `git add -u`, and ask the user before including extras. Aligned wording with the `CLAUDE.md` → Git Workflow → "Commit Scope — This Session Only" rule.

### 1.0.0 — 2026-04-16

- Initial release. End-of-session wrap-up skill with 8 phases: identify project, update project files, capture notes, capture draft insights, propagate to area files, continuous-improvement check, commit and push, summary.

---

## triage

### 1.0.3 — 2026-11-21 — public-release clean-up

- **Changed:** examples use a neutral Jira key.

### 1.0.2 — 2026-05-01

- **Changed:** Phase 1 step 4 — when the recommended priority order matches the source order, the skill now states that in one line and proceeds straight to the first item's analysis instead of asking for confirmation. Confirmation is only solicited when the recommended order differs from the source. The user can still interrupt at any time to add/remove/reorder.
- **Changed:** Phase 2 "Present" — analysis section relabelled `**What's going on:**` and rewritten to favour plain-language, decision-ready summaries over technical exposition. Added an explicit "Writing style for the analysis and options" guidance block (plain language over jargon, short sentences, lead with consequence not mechanism, concrete over abstract, no fluff hedging). Technical depth still happens during investigation; it stays out of the user-facing output unless genuinely required for the decision.
- **Added:** New "Important behaviors" entries — *"Translate the technical work into plain language"* and *"Don't ask for confirmation when there's nothing to confirm"* — codifying the two changes above.

### 1.0.1 — 2026-04-23

- **Changed:** Migrated to the current `plugins/<plugin>/.claude-plugin/plugin.json` layout (from the older `plugins/<plugin>/plugin.json`). No behaviour change; brings triage in line with wrap and with the layout recommended for new plugins in [CLAUDE.md](CLAUDE.md) and README. The marketplace `source` field is unchanged (still `./plugins/triage`) — Claude Code resolves `plugin.json` from either location.
- **Removed:** Cleaned up a stray `plugins/triage/{skills/triage}/` directory — empty, untracked, leftover from a failed brace-expansion on 2026-04-15.

### 1.0.0 — 2026-04-15

- Initial release. Iteratively process a list of items one by one — PR review comments, code review findings, analysis results, or any batch of decisions that need individual attention.

---

## pr-workflow

### 0.3.0 — 2026-11-26 — one flow, one actor per step

- **Changed (breaking):** the author never requests CodeRabbit reviews, posts `@coderabbitai approve`, asks for an approval, sets the gate status or merges; the approval moves to `pr-intake`, after the intake's own clean review and green required CI (closes #15). The author's independent review is no longer recorded in the PR description, and "mark ready on the user's request" is gone: PRs are never drafts and open only when the work is done.
- **Added to `pr-author`:** start from an agreed issue; what counts as an agreement or spec amendment; spec gaps go to the owner; who starts the independent review; everything said on the PR, with outcome replies (closes #7); the *"head `<sha>` ready"* hand-back after each fix round; a status block.
- **Added to `pr-intake`:** the 15-step flow with one actor per step; issue triage (closes #1); the impact analysis checks the PR against its issue's agreement and asks the owner only on a deviation, no agreement or a release; what counts as the owner's word; CodeRabbit review allocation; the `needs-owner` label; the approval; release PRs (the owner says "merge it", the intake approves and merges); holding merges during a PR's final cycle; an issue sweep on every wake (`pr-watch` watches PRs only); a status block. The approval waits for the gate status and required CI (part of the merge step).

### 0.2.1 — 2026-11-21 — public-release clean-up

- **Changed:** neutral SSH alias in the hook test; CodeRabbit review-trigger note no longer states an unsourced threshold.

### 0.2.0 — 2026-11-17 — pr-watch

- **Added:** `bin/pr-watch`, the intake session's watcher. It compares the open PRs of the intake repos against the last *handled* snapshot (kept in the plugin's data folder), so a change between a wake and the restart, or while no session runs, is never lost; `--handled` saves the snapshot that was reported. Each PR's `updatedAt` is part of the snapshot, so edited comments wake it. Zero open PRs is a valid state; a failed API call is a skipped poll, and five in a row exit 4. Replaces the workspace script it grew from.
- **Added:** a "Watching" section in `pr-intake`.

### 0.1.0 — 2026-11-17 — first release

- **Added:** `pr-author` and `pr-intake` skills (habits, author grants, intake rules), the `pr-guard` PreToolUse reminder hook and the `session-reset` SessionStart hook, five `userConfig` options, offline hook tests.
