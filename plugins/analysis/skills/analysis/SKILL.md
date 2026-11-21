---
name: analysis
description: Pick up one backlog item (an idea file, a GitHub or Jira issue, a pasted problem) with a decision-ready analysis. It validates that the problem is real and current, gathers cited evidence, recommends one solution with credible alternatives and their trade-offs, has it independently reviewed, lists every decision left for the owner, and stops for the owner's decision without implementing anything. Use when the user says "/analysis", "analyse this idea", "analyse this issue", "prepare an analysis of …", or "pick up <backlog item>". Do not use for "what are the options for …" (answer inline), or when capturing an idea ("idea: …") or filing an issue ("file an issue").
user-invocable: true
---

# Analysis

Turns one backlog item into a **decision-ready analysis**:
- the problem restated;
- what's true today, with evidence;
- a recommended solution plus any credible alternatives;
- every decision left for the owner;
- what the independent review covered.

**It stops for the owner's decision and never starts implementing.** No code edits, no issue comments, no tickets, unless the owner asks for them in step 8.

## Arguments

`/analysis <item>`, where `<item>` is a path to an idea or project file, a GitHub or Jira issue (URL or key), or a problem pasted as text.

## Dependencies

Step 5 runs the **`independent-review`** skill (plugin `independent-review` from the same marketplace) in caller mode. If that skill isn't available, say so before step 5 and ask the owner how to proceed. Never skip the review silently.

## Workspace detection

A **Consigliere (cg) workspace** is a directory with a `.cg.json` at its root. Find it from **the item's location**, not the cwd:
- an idea file or project path → walk up from the file to the directory holding `.cg.json`;
- an issue URL or key, or pasted text → ask once which workspace or repo it belongs to, **unless** the cwd is a cg workspace with a project that matches the item.

In a cg workspace, read its `CLAUDE.md` first. **Its rules govern where the analysis lives**: the session-start rule (project and area), the project structure, the worktree workflow and the idea lifecycle. The steps below are this skill's own and don't change.

## Sizes

Propose a size in step 0. The owner can override it.

| | Short | Full |
|---|---|---|
| When | One decision and no load-bearing assumption | Anything else |
| Steps | 0–8, inline | All, with an analysis document |
| Evidence (step 3) | Citations for load-bearing claims | Same |
| Review (step 5) | Fresh reviewer, scoped to the one decision. Save the analysis text to a scratch file (`<scratchpad>/analysis/<slug>.md`) for the review to pin. Write the coverage line into the decisions record or the idea's Notes (outside cg: the final message), **with its content hash**, since the scratch file may not outlive the session. Skip only when the item is really straightforward (one obvious answer, follows an existing pattern, trivially reversible); the coverage line then says `no independent review: <why>` | Fresh reviewer on the analysis document |
| Output | Conversation plus the decisions record | Analysis document ([template](templates/analysis.md)) |
| **Move up to full** | As soon as a second open decision or a load-bearing assumption appears | — |

## Where the output goes

- **In a cg workspace:** an analysis is meaningful work, so the workspace's session-start rule applies and the analysis belongs to a project.
  - **Full:** use the matching project, or propose one and create it through the workspace's project-creation workflow once the owner agrees. The document goes in `projects/<slug>/analysis.md` (`analysis-<topic>.md` when the project has several), decisions in `decisions.md`, and a line in `log.md`.
  - **Short analysis of an idea** while the idea is `exploring`: in the idea file's Notes. No project needed.
- **Outside cg:** ask once per repo where to save a full analysis (default `docs/analysis/YYYY-MM-DD-<slug>.md`), and remember the answer for the rest of the conversation only. A short analysis stays in the conversation, and its decisions are listed in the final message.
- **On the source** (an issue or Jira comment): only when the owner asks. It is outward-facing, and an issue thread is a poor home for a long, revised analysis.

## Step 0 — Intake

1. Read the item in full: the idea file, the issue with its comments, or the pasted text.
2. Resolve the workspace (above). In cg, settle the project and worktree as the workspace's rules require before writing anything.
3. **Restate the problem** in two or three sentences: the observable behaviour or gap, and who it affects.
4. **State whether it's a "whether" or a "how" item.** A hunch or "should we …" settles *whether* before any *how*. State the classification; don't ask for it.
5. **Propose the size** (Short or Full) with one line of why.

## Step 1 — Recon and validate

**Recon.** Read the code, configuration, docs and records until you can describe today's behaviour. For a change, write down **current / expected / unchanged** behaviour. Look for existing solutions:
- **internal:** this repo or workspace, and the environment's own tooling: the plugins and skills installed in this session, the framework and its extensions, and the owner's own plugin and extension repos;
- **external:** established tools.

**Never ask what the sources answer.**

**Record what recon checked:** each source, and what it turned up or "nothing found". A miss then shows in the analysis. Full: in the document's Current state. Short: one line when presenting in step 6.

**Validate the item itself. Never skipped: a report is a claim, not evidence.** Answer each question with evidence:
- **Does the problem exist?** Bug: reproduce it or trace it (a reproduction or trace, a hypothesis with evidence, one alternative ruled out). Feature: is the gap real, or is it already covered?
- **Is the expected behaviour right?** Does it work as intended? Is the intended behaviour documented?
- **Is it still current?** Already fixed, duplicate, stale, overtaken by other work?
- **Is it the right problem?** Symptom or cause? The asked-for solution, or the need behind it?

**Validity verdict:**
- **valid** → continue;
- **partly valid** → restate the real problem and continue with that;
- **not valid** → skip step 4 and go to step 6 with the verdict "don't proceed" and the evidence. Propose a closing reply for the source; post it only when asked. The verdict and its evidence are recorded in step 7: in cg, in the decisions record (or the idea's Notes); elsewhere, in the final message.

Effort is proportional. A clear-cut case takes a few lines, but the verdict is always stated.

## Step 2 — Framing check

- **Framing open** (a capability may be missing, a constraint hasn't surfaced yet): present the findings in prose with **one candidate framing**, and invite a reframe. **No menu, no `AskUserQuestion`.** Wait for the answer.
- **Framing settled, but a question blocks the analysis:** ask at most 3, **one at a time**. Each leads with a recommended answer that "yes" accepts.
- **Nothing blocks:** skip the step.

## Step 3 — Evidence

- Every load-bearing claim is **cited** (`file:line`, or a URL with its date or version), or tagged **assumption** with a confidence of high, med or low. A claim is load-bearing if it justifies the recommendation, would flip it if false, or will be quoted elsewhere.
- **Verify external, time-sensitive claims at the source** (vendors, pricing, licences, versions, project status), not from memory.
- "Couldn't verify" is stated as such, never reported as fine.
- In a cg workspace whose records carry an `authority:` field (`own`, `mirror`, `observed`), check it. Re-verify `mirror` and `observed` records at their source. A record with no `authority:` is unclassified, not `own`.

## Step 4 — Options

- **One recommendation.** Add **0–3 alternatives**, only credible ones. One recommendation is enough when it clearly dominates.
- Consider **"smallest thing that works"** and **"do nothing"**, and include them when they are credible.
- Each option gets its **trade-off**, **when it's the wrong choice**, and its **rabbit holes**.
- An option that adopts a third-party tool also carries its **durability facts**, each with a source: who owns it, licence, hosted or self-hosted, cost on the owner's plan, and the exit path if the vendor changes terms.
- The runner-up gets **"wins instead if …"**.
- Then the **hidden-constraints check**: reversibility, failure mid-operation, data and compliance, security, performance, dependencies, operations, and who else is affected.

For a full analysis, write the document now from [templates/analysis.md](templates/analysis.md), so step 5 has a file to pin. Leave `Verdict` as `pending review`.

## Step 5 — Independent review

A **blocking gate** before step 6. The default at both sizes; skip only as the Sizes table allows.

1. **Run the review skill in caller mode.** Use the Skill tool with `independent-review` (namespaced `independent-review:independent-review`). In the args give:
   - the target: the analysis document's path (full), or the scratch file (short);
   - `caller mode: analysis skill`;
   - the kind: `analysis`, and the lenses: builder check, claim check, missed option, hidden constraints, governing rules;
   - its sources: the files and URLs the analysis cites;
   - `do not write log.md; the caller records it` (in caller mode the record is the caller's, step 3);
   - from round 2 on: **the round number, the previous version and snapshot path, and the earlier findings** to regression-check. The previous version is the content hash in the last returned coverage block. The review skill saved its snapshot at `<scratchpad>/independent-review/snapshots/<target-filename>-<hash>`; check that the file exists before passing it. Without these inputs the review treats the call as round 1, and the regression check against earlier findings is lost.
2. **Use the returned piles as they are.** The review skill validates and sorts the findings itself: fix / owner's / rejected; builder questions: answered / minor / owner's.
3. **Write the returned coverage block** into the analysis's `Review` section (short: into the decisions record or idea Notes, with the content hash). In cg, also add the review's line to the project's `log.md`: in caller mode, the record is yours.
4. **Apply the fix pile** to the analysis. **If the fix pile is empty,** there's nothing to re-review: go to step 6.
5. **After any substantive fix, call again for the delta round**, until a round comes back `clean`. There is no round limit: don't pass one. If a round's remaining blockers and should-fixes are all in the owner's pile, there is nothing to fix: continue to step 6 with them listed.

## Step 6 — Present

In this order:
1. **The validity verdict** from step 1.
2. **The recommendation and the alternatives.**
3. **Every open decision**, in a table (decision, recommended answer, status). **Approval covers only what is listed.**
4. **A coverage line:** which review ran, on what version, and what wasn't verified.
5. **A verdict:** proceed / needs clarification / don't proceed.

**These force "needs clarification":**
- any assumption that could flip the recommendation, until it's verified (checking it is a prerequisite, not a follow-up);
- the review's **owner's findings** and **open owner's builder questions** (returned even on a clean round; list them in the decision table);
- a last review round that isn't `clean`.

For a full analysis, give a short summary and the document's path; don't paste the whole document.

## Step 7 — Record

- The owner's answers go into the analysis's **Q→A log**.
- Decisions go into the decisions record **with their assumption tags**: an inference never becomes a decision stated as fact.
- In cg: `decisions.md` with the next DEC numbers, rejected alternatives kept; update the project's `README.md` and `log.md` per the workspace's rules.
- Outside cg: the analysis document (full) or the final message (short).

## Step 8 — Hand-off

**Propose** the next step. Create it only once the owner says so:
- **implement now** (in a new turn, under the repo's normal workflow);
- **a project or todo items**;
- **a stored plan for the owner to implement**, always offered beside "implement now". It must be self-implementable: per item, `file:line`, root cause, verdict, confidence, and what to confirm while implementing. Update `todo.md` in cg. No code is edited;
- for a **greenfield build** that wants specs, the workspace's spec-driven workflow, where one exists.

A new decision found later, during implementation, goes back to the owner: stop and ask.

## Never

- Implement, edit code, or open a PR during the analysis.
- Post to the source issue or ticket without being asked.
- Present a recommendation without the review (or a stated reason it was skipped).
- Turn an assumption into a decision stated as fact.
- Ask what the sources already answer.

## Attribution

"Look before you ask" and the builder check follow obra/superpowers `brainstorming` (MIT). The question shape (one at a time, a recommended answer first) follows GitHub spec-kit `clarify`, and the citation-or-assumption tags, the "smallest thing that works" and "do nothing" options, rabbit holes and the proceed / needs clarification / don't proceed verdict follow the spec-kit `assess` bundle (both MIT). The runner-up's "wins instead if …" follows BMAD-METHOD `bmad-deep-recon` (MIT per its docs). All are re-expressed here, not copied.
