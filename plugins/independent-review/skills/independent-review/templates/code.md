# Brief template: code

Fill in every `{{…}}`. Delete lines that don't apply. Never paste the conversation or your own reasoning about the change.

---

Review this code change. **Round {{ROUND}}{{DELTA_NOTE}}.**

- **Repo:** {{REPO_NAME}}
- **Checkout (detached at the pinned commit; work only here):** `{{CHECKOUT_PATH}}`
- **Pinned version:** {{VERSION}} (e.g. `head abc1234`, or `uncommitted snapshot 9f8e7d6 of abc1234`)
- **Base:** `{{BASE_SHA}}`. Review `git diff {{BASE_SHA}}...{{HEAD_SHA}}`{{SNAPSHOT_DIFF_NOTE}}. Both are SHAs: inside the checkout, `HEAD` and branch names don't mean what they mean in the author's clone.
- **What it says it does** (testimony; verify it): {{DESCRIPTION}}. Includes the PR description, the docs changes and any "verified" or compatibility statements, quoted or linked.
- **Claims to check:**
  {{CLAIMS}}
- **Probes for this change:**
  {{PROBES}}
  - edge cases this change could break; other places that enumerate the same thing; update and uninstall paths
  - missing, empty or unexpected values in optional fields, and how grouping, sorting and counting treat them
  - **when you find a validation gap on one input, check every other input that takes the same kind of value** (other flags, other commands, files edited by hand)
  - the repo's own rules (`CLAUDE.md`, `CONTRIBUTING`): does the change follow them
  {{PORTABILITY_PROBE}}
- **Tests and linters** (run by the skill before you started; mode: {{TEST_MODE}}; in `container` mode, the only way to re-run them is this command line: {{CONTAINER_COMMAND}}): {{TEST_RESULTS}}
{{DELTA_BLOCK}}
- **Word cap:** {{WORD_CAP}} words.

Follow your agent rules and output format.

---

**Delta block** (rounds 2+). Replace `{{DELTA_BLOCK}}` with:

```
- **Earlier findings to regression-check** (confirm each is really fixed, not just claimed):
  {{EARLIER_FINDINGS}}
- **Scope:** only `git diff {{PREVIOUS_HEAD_SHA}} {{HEAD_SHA}}` and its direct effects. Don't re-review the rest.
```

**Portability probe** (only for repos that ship to more than one platform, such as Windows): path separators in stored data vs `filepath`, CRLF content and checkouts, executable bits and `chmod`, file locking, renaming or deleting open files, and shelling out to `sh` or Unix-only tools.
