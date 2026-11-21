---
name: triage
description: Iteratively process a list of items one by one — PR review comments, code review findings, analysis results, Jira issues, or any batch of questions/decisions that need individual attention. Use this skill whenever the user wants to go through multiple items systematically, such as "triage these review comments", "let's go through these issues one by one", "process these findings", "review the comments on PR #123", "go through the analysis results", or any situation where there's a list of things that each need a decision. Also triggers when the user has just received output containing multiple items (like a code review, an audit, or a list of questions) and wants to work through them.
user_invocable: true
---

# Triage

Process a list of items one by one with thorough analysis, clear options, and actionable recommendations. Each item gets your full attention before moving to the next.

## When to use

- User has a list of review comments, issues, questions, or findings to work through
- User received output with multiple actionable items and wants to resolve them systematically
- User references a PR, issue, or analysis that contains multiple items to address
- User says things like "let's go through these", "one by one", "triage", "process these"

## Arguments

The user provides a **source** of items. This can be:
- A GitHub PR URL or number (e.g., `#123`, `org/repo#45`) — fetches review comments automatically
- A Jira issue key (e.g., `PROJ-1234`) — fetches comments or subtasks
- A file path — reads the file and extracts items
- Pasted text — items listed directly in the message
- A reference to previous output — e.g., "triage the findings from above"

Example invocations:
- `/triage #123` — process review comments from PR #123
- `/triage PROJ-567` — process items from a Jira issue
- `/triage ./audit-results.md` — process items from a file
- `/triage` (with items pasted in the same message)
- "let's go through those review comments one by one"
- "triage the issues from the analysis above"

## Phase 1: Extract Items

Identify and fetch items from the source:

1. **Determine the source type** from the user's input:
   - **GitHub PR**: Use `gh pr view <number> --json comments,reviews` and `gh api repos/{owner}/{repo}/pulls/{number}/comments` to fetch all review comments. Group by conversation thread where applicable.
   - **Jira issue**: Use the Jira MCP tools to fetch issue details, comments, and linked items.
   - **File**: Read the file and parse out distinct items (numbered lists, bullet points, headings, or logical sections).
   - **Pasted text / conversation context**: Parse the text for distinct items. Look for numbered lists, bullet points, separate paragraphs, or distinct questions.

2. **Create a numbered checklist** of all extracted items. For each item, capture:
   - A short title (one line summary)
   - The full original text/context
   - The source location (file path + line, PR comment URL, etc.)

3. **Present the full list** to the user as a numbered overview:
   ```
   Found 8 items to triage:
   1. [ ] Missing null check in parseConfig  (reviewer: alice)
   2. [ ] Consider using Map instead of Object  (reviewer: bob)
   3. [ ] Test coverage for edge case  (reviewer: alice)
   ...
   ```

4. **Assess priority order.** Compare the order you'd recommend (e.g., blocking comments before nits, security before style) against the source order:
   - **If your recommended order matches the source order** — say so in one line ("order looks fine, starting with item 1") and **proceed directly to Phase 2 with the first item**. Do not ask for confirmation.
   - **If your recommended order differs** — show the proposed reordering with a brief reason and ask the user to confirm or adjust before proceeding.
   - The user can always interrupt to add/remove/reorder items at any point — no need to prompt for it when the order is uncontroversial.

## Phase 2: Process Items One by One

For each item, go through this cycle:

### Present

Show the item with this structure:

```
## Item 3/12: [Short title]

**Source:** [where this came from — reviewer name, file:line, etc.]

**Context:**
[The original comment/issue text, quoted verbatim]

**What's going on:**
[Plain-language explanation of what the item is asking and why it
matters. Write so a reader who hasn't seen the code can follow.
Avoid jargon when a normal word works; spell out acronyms on first
use; show concrete examples instead of abstract descriptions. Read
the relevant code first so the explanation is grounded — but in the
output, lead with the *what* and *why*, not the technical drill-down.
Aim for 2–4 short sentences. If a longer technical detail is genuinely
needed for the decision, put it in a separate "Technical detail:"
sub-line below — don't bury the main point in it.]

**Options:**
A) [First option — described in plain words, with the practical effect]
B) [Second option — same]
C) [Third option if applicable]
D) Skip — defer to later

**Recommendation:** [One option, one sentence on why, in plain language.
Be opinionated — the user wants a clear suggestion, not a fence-sit.]
```

**Writing style for the analysis and options.** The user reads this output to make a decision quickly. Optimise for *understandability*, not technical depth:

- Plain language over jargon. *"This sets up a race condition between two writers"* beats *"non-atomic compare-and-swap on the shared mutable reference"*.
- Short sentences. Cut filler ("basically", "essentially", "it turns out that").
- Lead with the consequence, not the mechanism. *"If two requests hit at the same time, one overwrites the other"* before *"because the lock is acquired after the read"*.
- Concrete over abstract. Name the function, file, or behaviour; show a one-line example if it clarifies.
- No fluff hedging. Skip "it might be worth considering whether perhaps…". Say it.
- Read the code, then translate. Your job is to do the technical work *behind the scenes* and present the user with the decision-ready summary — not to dump the technical detail on them.

### Wait for Decision

The user will respond with one of:
- **A choice** (e.g., "A", "go with B", "option C") — proceed to implement/capture
- **A follow-up question** — answer it thoroughly, then re-present options if needed
- **"skip"** — mark as deferred, move to next item
- **"batch"** — user wants to apply the same decision to similar items (see Batch Mode below)
- **A custom decision** not in the listed options — that's fine, proceed with what they said

### Implement or Capture

Based on the decision:

- **If the change is small and clear** (a few lines of code, a config tweak, a comment reply): implement it immediately. Show the diff or result.
- **If the change is larger or needs more thought**: capture it as a detailed task description. The description should include enough context that someone (or a future Claude session) could implement it without re-reading the original discussion. Ask the user where to store it — common destinations:
  - A project's `todo.md` (if working in a structured project)
  - A new issue or comment (if working in GitHub/Jira)
  - A file the user specifies
  - If it's not clear where tasks should go, ask the user once at the beginning and reuse that answer for the rest of the session.

### Advance

After implementing or capturing:
1. Mark the item as done in the checklist
2. Show progress: `[3/12 done, 1 skipped]`
3. Present the next item

## Batch Mode

When the user says "batch" or indicates they want to handle similar items together:

1. Show which remaining items you think are similar to the current one (e.g., all nit-level style comments, all items from the same reviewer about the same topic)
2. Let the user confirm or adjust the batch
3. Apply the same decision to all items in the batch
4. Show what was done for each, briefly
5. Continue with the next non-batched item

## Phase 3: Summary

After all items are processed (or the user says they're done), present a summary:

```
## Triage Complete: 12 items processed

### Implemented (7)
- #1: Added null check in parseConfig — [link to diff/file]
- #3: Added test for edge case — [link to diff/file]
- ...

### Captured as tasks (3)
- #5: Refactor auth middleware — captured in projects/auth-rework/todo.md
- ...

### Skipped / Deferred (2)
- #8: Performance optimization — reason: needs benchmarking first
- #11: API versioning question — reason: waiting for team input
```

If there are deferred items, ask if the user wants to come back to any of them now.

## Important Behaviors

- **Read before you recommend.** When an item references code, read the actual code before presenting options. Uninformed recommendations waste the user's time.
- **Translate the technical work into plain language.** Do the deep reading yourself; present the user with a decision-ready summary in everyday words. Technical depth lives in your investigation, not in the output.
- **Be opinionated.** The user wants a recommendation, not a balanced essay. Take a position and explain why.
- **Don't ask for confirmation when there's nothing to confirm.** If your priority order matches the source order, just start. If a decision is unambiguous, just take it. Save user prompts for genuine forks.
- **Respect the user's pace.** Present one item at a time. Don't rush ahead or present multiple items in one response.
- **Track state.** Always know which items are done, skipped, and remaining. Show progress consistently.
- **Handle interruptions gracefully.** If the user goes on a tangent or asks about something unrelated mid-triage, address it and then offer to continue where you left off.
