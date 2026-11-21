# independent-review

Independent, fresh-context review as one repeatable step.

```
/independent-review <PR | branch | A..B | uncommitted | path> [--baseline <path|url>] [--split-lenses]
```

**What it does:**
- **Pins** the exact version under review (commit SHA, stash snapshot, or content hash plus a snapshot copy).
- **Briefs** a reviewer that never saw the conversation, using the template for the target type:
  - **code:** a claims check against the PR description, probes for this change, tests;
  - **design:** builder check, claim check, missed option, hidden constraints, governing rules;
  - **document:** claim check, omissions against the original, governing rules, audience.
- **Validates every finding** before acting, then sorts the findings and builder questions.
- **Records** what each round covered and what it didn't verify.
- **Re-reviews only what changed** until a round is clean, with no round limit (a calling skill can set one).
- **Keeps the record out of PR descriptions:** for a PR it stays in the conversation (or the caller's own record).

**Read-only:**
- `doc-reviewer` is read-only by its tool list.
- `code-reviewer` works in a throwaway detached checkout at the pinned commit.
- For code in the session's own repo, the built-in `/code-review` adds a second opinion.

**Caller mode:** another skill can run it and get back the findings, the open questions and the coverage block, without its own target being edited.

**Limits:**
- One reviewer is a sample, not a sweep. Repeated runs on the same target find overlapping but different sets. Use `--split-lenses` for high-stakes targets.
- Untracked files aren't in an uncommitted snapshot.
- `/code-review` is only used for targets in the session's own repo.
