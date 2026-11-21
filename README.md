# Claude Code Plugin Marketplace

Personal plugin marketplace for custom Claude Code skills and MCP plugins.

## Available Plugins

| Plugin | Skill | Description |
|---|---|---|
| `triage` | `/triage` | Iteratively process a list of items one by one — PR review comments, code review findings, analysis results, or any batch of decisions |
| `analysis` | `/analysis` | Pick up one backlog item with a decision-ready analysis: validated problem, cited evidence, a recommendation with alternatives, an independent review and every open decision listed. Never implements |
| `pr-workflow` | `pr-workflow:pr-author`, `pr-workflow:pr-intake` | Rules for agents working on pull requests (author habits and grants, maintainer intake), configured per repo, with a reminder hook |
| `independent-review` | `/independent-review` | Independent, fresh-context review of a PR, branch, design or document, with a pinned version, validated findings, a coverage record and delta re-review |

`wrap` was removed on 2026-10-02: it ships with [consigliere](https://github.com/mnemcik/consigliere) (`cg init` installs it, `cg sync` keeps it current).

See [CHANGELOG.md](CHANGELOG.md) for version history and per-plugin release notes.

## Usage

### Adding the marketplace

**Option 1 — Interactive (once per machine):**

```sh
/plugin marketplace add mnemcik/claude-marketplace
```

**Option 2 — Settings file** (add to `~/.claude/settings.json` or project `.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "mnemcik": {
      "source": {
        "source": "github",
        "repo": "mnemcik/claude-marketplace"
      }
    }
  }
}
```

### Installing plugins

After adding the marketplace, enable plugins in settings:

```json
{
  "enabledPlugins": {
    "triage@mnemcik": true,
    "independent-review@mnemcik": true,
    "analysis@mnemcik": true
  }
}
```

### Using a skill

Once installed, invoke with:

```sh
/triage
```

Or use natural language — "let's go through these one by one", "triage these review comments", etc.

## Adding a New Plugin

1. Create a directory under `plugins/` using the current layout:
   ```
   plugins/my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json
   └── skills/
       └── my-skill/
           └── SKILL.md
   ```

2. Write `plugin.json` with plugin metadata (include `"version": "1.0.0"`)
3. Write `SKILL.md` with skill instructions
4. Add the plugin to `.claude-plugin/marketplace.json` — the `version` field **must match** the plugin's own `plugin.json`
5. Add a `## my-plugin` section to [`CHANGELOG.md`](CHANGELOG.md) with an initial `1.0.0` entry
6. Bump the top-level `version` in `.claude-plugin/marketplace.json` (adding a plugin changes the manifest shape — see [CLAUDE.md](CLAUDE.md) for the policy)
7. Commit and push

## Releasing a New Version of an Existing Plugin

A plugin's version is duplicated in **three files** that must move together. Missing any one causes drift (historical examples: wrap 1.0.3, 1.0.4, 1.0.5). Use this checklist on every bump:

1. ☐ `plugins/<plugin>/.../plugin.json` — new `version`
2. ☐ `.claude-plugin/marketplace.json` — the `plugins[]` entry's `version` for that plugin
3. ☐ `CHANGELOG.md` — new `### X.Y.Z — YYYY-MM-DD` entry under the plugin's section
4. ☐ If `SKILL.md` (or any other file) prose mentions the version, update it too
5. ☐ `git status` — confirm all the above files are staged
6. ☐ Commit message starts with `<plugin> X.Y.Z — <one-line summary>`

See [CLAUDE.md](CLAUDE.md) for the full rule (including SemVer guidance and the top-level `marketplace.json` version policy).

## Workflow

This is a personal marketplace — **commit directly to `main`**, no pull requests required. Every version-bump commit must still add an entry to `CHANGELOG.md` under the relevant plugin section; if a change isn't worth a changelog line, it isn't worth a version bump.
