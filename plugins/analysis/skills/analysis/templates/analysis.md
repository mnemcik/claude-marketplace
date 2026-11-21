---
title: "Analysis — {{TITLE}}"
created: {{YYYY-MM-DD}}
item: "{{ITEM}}"  # idea path, issue URL or key, or "pasted"
size: full
verdict: pending review  # proceed | needs clarification | don't proceed
{{CG_FIELDS}}
---

<!-- In a cg workspace, replace {{CG_FIELDS}} with the frontmatter its notes use (for example `areas: [...]`); elsewhere delete the line. -->

# Analysis — {{TITLE}}

## Question

{{The problem restated in 2–3 sentences: the observable behaviour or gap, and who it affects. Whether it's a "whether" or a "how" item.}}

## Current state (evidence)

{{Today's behaviour, every load-bearing claim cited (`file:line`, or URL with date or version) or tagged `assumption (high|med|low)`. For a change: current / expected / unchanged behaviour. Existing solutions found, internal and external. What couldn't be verified.}}

**Recon checked:** {{each source checked (repo or workspace, installed plugins and skills, the framework and its extensions, the owner's own plugin and extension repos, external tools) and what it turned up, or "nothing found"}}

## Validity

| Question | Answer | Evidence |
|---|---|---|
| Does the problem exist? | | |
| Is the expected behaviour right? | | |
| Is it still current? | | |
| Is it the right problem? | | |

**Verdict:** {{valid | partly valid (real problem: …) | not valid}}

## Options

### Recommended — {{name}}

- **What:** 
- **Trade-off:** 
- **Wrong choice when:** 
- **Rabbit holes:** 
- **Durability** (only when it adopts a third-party tool; each with a source): owner, licence, hosted or self-hosted, cost on the owner's plan, exit path

### Alternative — {{name}} (runner-up)

- **What:** 
- **Trade-off:** 
- **Wrong choice when:** 
- **Rabbit holes:** 
- **Wins instead if:** 

<!-- 0–3 alternatives, credible ones only. Consider "smallest thing that works" and "do nothing". -->

## Hidden constraints

Reversibility · failure mid-operation · data and compliance · security · performance · dependencies · operations · who else is affected.

## Open decisions

| # | Decision | Recommended answer | Status |
|---|---|---|---|
| 1 | | | open |

## Review

{{One coverage block per round, as returned by the review skill. Or: "no independent review: <why>".}}

## Verdict

{{proceed | needs clarification | don't proceed}}: {{one line of why; list what forces "needs clarification"}}

## Q→A log

- {{YYYY-MM-DD}} — Q: … → A: …
