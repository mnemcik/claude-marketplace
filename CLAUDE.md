# CLAUDE.md

This file tells AI coding tools (Claude Code, Cursor, etc.) how to work in this repository.

## Purpose

Personal Claude Code plugin marketplace. Hosts custom skills (`triage`, …) and, eventually, MCP plugins. Consumed via `/plugin marketplace add mnemcik/claude-marketplace`.

## Workflow

- **Changes land through pull requests** on a protected `main`; no direct pushes.
- **Every change to a plugin's files bumps that plugin's version** (at least a patch) **and adds its `CHANGELOG.md` entry** under the plugin's section. Installed copies update only when the version changes, so an unbumped change never reaches anyone.

## Versioning — Single Source of Truth

Each plugin's version lives in **three places** that must stay in lockstep:

| # | File | What it is |
|---|------|-----------|
| 1 | `plugins/<plugin>/.claude-plugin/plugin.json` (or `plugins/<plugin>/plugin.json` — older layout) | The plugin's canonical `version` field |
| 2 | `.claude-plugin/marketplace.json` — the `plugins[]` entry for that plugin | The version the marketplace manifest advertises |
| 3 | `CHANGELOG.md` — the plugin's section | Release notes for the bumped version |

**A version bump is complete only when all three are updated in the same commit.** Missing any one causes drift and misleads users: the marketplace advertises one version while the plugin itself is another, or the changelog has no entry for what shipped. This has happened three times (wrap 1.0.3, 1.0.4, 1.0.5 — see CHANGELOG entries for the reconciliations).

### Version-bump checklist

Before committing any change that bumps a plugin version:

1. ☐ Update `plugins/<plugin>/.../plugin.json` → new version
2. ☐ Update `.claude-plugin/marketplace.json` → `plugins[].version` for that plugin
3. ☐ Add a `### X.Y.Z — YYYY-MM-DD` entry under the plugin's section in `CHANGELOG.md`
4. ☐ (If the skill mentions its version in `SKILL.md` prose) update that reference
5. ☐ `git status` — confirm all three (or four) files are staged
6. ☐ Commit message starts with `<plugin> X.Y.Z — <one-line summary>`

The `CHANGELOG.md` convention line (the "if it's not worth a changelog line…" rule) is your safety net: writing the changelog entry forces you to confront whether the version bump is real, and to notice the other two files aren't staged yet.

### SemVer guidance for skills

- **Patch** (`1.0.X`): bug fix, doc-only change to `SKILL.md`, rename that doesn't alter behaviour.
- **Minor** (`1.X.0`): new phase, new capability, additional trigger, behaviour added without removing old behaviour.
- **Major** (`X.0.0`): breaking change — phases renumbered in a way that changes observable output, removed behaviour, incompatible config.
- **Below `1.0.0`**, a breaking change bumps the minor (`0.X.0`), as SemVer allows; the changelog marks it "(breaking)".

### Top-level `marketplace.json` `version` field

The `version` at the top of `.claude-plugin/marketplace.json` is the **marketplace manifest version**, not an aggregate of plugin versions. Policy:

- Do **not** bump it on every plugin version change.
- Bump it when the manifest **shape** changes materially: a plugin is added, a plugin is removed, a plugin's `name` / `source` changes, or the manifest adopts a new schema field.
- Current value (`1.0.0`) reflects the manifest schema as of the initial release + wrap addition. Future additions (MCP plugins etc.) should bump this.

Rationale: consumers resolve per-plugin versions from the `plugins[].version` entries — that's the field that matters to them. The top-level `version` mostly tells tooling "this manifest changed in a non-backwards-compatible way".

## Plugin Layout

Two layouts currently coexist:

- Newer: `plugins/<plugin>/.claude-plugin/plugin.json` + `plugins/<plugin>/skills/<skill>/SKILL.md` (used by `triage`, `independent-review` and `analysis`; `independent-review` also ships `agents/`)
- Older: `plugins/<plugin>/plugin.json` + `plugins/<plugin>/skills/<skill>/SKILL.md` (no current plugin)

Both work. **New plugins should use the newer `.claude-plugin/` layout.**

## Where work is tracked

Bugs, enhancement ideas and release follow-ups are tracked in this repo's issues. Release notes live in `CHANGELOG.md`, rules in this file.
