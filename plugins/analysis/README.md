# analysis

The first step of picking up a backlog item, as one repeatable skill.

```
/analysis <idea file | project path | GitHub or Jira issue | pasted problem>
```

**What it does:**
- **Validates the item** before anything else: does the problem exist, is the expected behaviour right, is it still current, is it the right problem. A report is a claim, not evidence.
- **Gathers evidence:** every load-bearing claim cited or tagged as an assumption with a confidence; time-sensitive external claims checked at the source.
- **Recommends one option**, with 0–3 credible alternatives, each with its trade-off, when it's the wrong choice and its rabbit holes, plus a hidden-constraints check.
- **Has it independently reviewed** through the `independent-review` skill in caller mode, re-reviewing after fixes until a round is clean, with no round limit.
- **Presents** the verdict (proceed / needs clarification / don't proceed) and every open decision in a table, then **stops**. It proposes the hand-off and never implements.

**Sizes:** short (one decision, inline) or full (an analysis document from `templates/analysis.md`).

**Where the output goes:**
- In a [Consigliere](https://github.com/mnemcik/consigliere) workspace (detected by `.cg.json`): the project's `analysis.md`, `decisions.md` and `log.md`, or the idea file's Notes for a short analysis.
- Elsewhere: asks once per repo (default `docs/analysis/YYYY-MM-DD-<slug>.md`).
- Never on the source issue unless asked.

**Requires:** the `independent-review` plugin from this marketplace.

**Install:**

```
/plugin install independent-review@mnemcik
/plugin install analysis@mnemcik
```
