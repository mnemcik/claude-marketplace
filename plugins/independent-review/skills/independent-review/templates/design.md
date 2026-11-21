# Brief template: design

For designs, analyses, recommendations, ADRs and plans. Fill in every `{{…}}`. Delete lines that don't apply. Never paste the conversation or your own reasoning about the design.

---

Review this {{KIND}} (design / analysis / recommendation / ADR / plan). **Round {{ROUND}}{{DELTA_NOTE}}.**

- **Target:** `{{PATH}}` at {{VERSION}} (e.g. `commit abc1234`, or `content hash 3b18e51…, uncommitted`). **Read it from the pinned snapshot `{{SNAPSHOT_PATH}}`**, not from the live path, which may change while you work.
- **What it's for:** {{PURPOSE}} (one line: what decision or build it drives)
- **Its sources** (pinned; read them, and re-verify the load-bearing claims against them):
  {{SOURCES}}
- **The system it changes** (read it for current behaviour): {{SYSTEM_PATHS}}
- **Lenses:**
  1. **Builder check.** You must act on this document without being able to ask its author. List the questions where a wrong guess would change what gets built or decided, ranked by impact.
  2. **Claim check.** Re-verify each load-bearing claim (facts about code, tools, vendors, versions, earlier decisions) at its source. Flag unsupported or contradicted claims.
  3. **Missed option.** Is there a simpler design, or an option that wasn't considered and would win?
  4. **Hidden constraints:** reversibility, failure mid-operation, data and compliance, security, performance, dependencies, operations, and who else is affected.
  5. **Governing rules.** Read the rules of the repo or workspace the target lives in: `CLAUDE.md`, `CONTRIBUTING`, and any rule files it points to ({{GOVERNING_RULES}}). Check the target against them, including anything it **relies on** that those rules say not to rely on or apply (for example drafts, deprecated APIs, unapproved decisions). Also check the things it cites as its basis, not just that they exist.
  {{EXTRA_LENSES}}
- **Requirements it must meet:** {{REQUIREMENTS}} (paths or a short list)
{{DELTA_BLOCK}}
- **Word cap:** {{WORD_CAP}} words.

Follow your agent rules and output format.

---

**Delta block** (rounds 2+). Replace `{{DELTA_BLOCK}}` with:

```
- **Earlier findings to regression-check** (confirm each is resolved by the text now, not just claimed):
  {{EARLIER_FINDINGS}}
- **Scope:** what changed since the last round. The diff is saved at `{{DELTA_DIFF_PATH}}`; read it. Look for new problems the changes introduced, and don't re-review the rest.
```
