# Brief template: document

For guides, runbooks, PRDs, Jira text, and messages or documents meant for other people. Fill in every `{{…}}`. Delete lines that don't apply. Never paste the conversation or your own reasoning about the document.

---

Review this document. **Round {{ROUND}}{{DELTA_NOTE}}.**

- **Target:** `{{PATH}}` at {{VERSION}}. **Read it from the pinned snapshot `{{SNAPSHOT_PATH}}`**, not from the live path.
- **Audience:** {{AUDIENCE}} (who reads it, and what they should do with it)
- **Baseline:** {{BASELINE}}. This is the original the document replaces, rewrites, migrates or summarises, pinned by commit or URL and date. **Review against the baseline itself, not against the document's own description of it.** Write "none" if there is no baseline.
- **Its sources** (pinned): {{SOURCES}}
- **Lenses:**
  1. **Claim check.** Re-verify each load-bearing claim at its source. Flag unsupported or contradicted claims.
  2. **Omissions against the baseline.** What the baseline covers that this document drops, weakens or changes without saying so. A review that only looks at what's there can't see what's missing. In particular:
     - **Orphaned terms:** for each term the baseline *defines* that the document still *uses*, check that the definition survived.
     - **Steppability:** every action the document names can be carried out from it, or it links to where it can.
  3. **Governing rules.** Check the document against the rules of the repo or workspace it lives in ({{GOVERNING_RULES}}), and the conventions of where it will be published.
  4. **Audience and scope.** It should hold only what's in scope and actionable for this reader. Flag content the reader can't act on, and gaps that would leave them stuck.
  {{EXTRA_LENSES}}
{{DELTA_BLOCK}}
- **Word cap:** {{WORD_CAP}} words.

Follow your agent rules and output format.

---

**Delta block** (rounds 2+). Replace `{{DELTA_BLOCK}}` with:

```
- **Earlier findings to regression-check:**
  {{EARLIER_FINDINGS}}
- **Scope:** what changed since the last round. The diff is saved at `{{DELTA_DIFF_PATH}}`; read it. Look for new problems the changes introduced, and don't re-review the rest.
```
