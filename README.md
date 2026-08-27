# godot-skills

A efficient and lightweight Agent Skills plugin for Godot 4.7+. Works with Claude Code, Codex, and Pi Coding Agent.

## Install

### Claude Code

```sh
/plugin marketplace add lanstar/godot-skills
/plugin install godot-skills@godot-skills
```

If the install summary says `Run /reload-plugins to activate.`, run that command.

### Codex

```sh
codex plugin marketplace add https://github.com/lanstar/godot-skills
codex plugin add godot-skills@godot-skills
```

### Pi Coding Agent

```sh
pi install godot-skills
```

### Local development

Load from a working copy without installing:

```sh
claude --plugin-dir /absolute/path/to/godot-skills          # session only
codex plugin marketplace add /absolute/path/to/godot-skills
pi install /absolute/path/to/godot-skills
```

All hosts discover `skills/*/SKILL.md` automatically.

## Design philosophy

We assume modern frontier LLMs already have sufficient reasoning ability and need minimal guidance. Skills should cover only information the model is unlikely to know or recall accurately, or topics where it may confuse details or be unsure of the correct approach, such as new or easily confused syntax, version-specific APIs, similarly named methods or nodes, or tasks with non-obvious implementation choices.

## Architecture

```text
.claude-plugin/plugin.json  Claude Code metadata
.codex-plugin/plugin.json   Codex plugin metadata
.agents/plugins/marketplace.json  Codex local marketplace entry
package.json                Pi package metadata
AGENTS.md                   Shared instructions (CLAUDE.md symlinks here)
skills/*/SKILL.md           Portable Agent Skills
```

The plugin intentionally has no hooks, MCP server, runtime code, or dependencies.

## Release

```sh
npm version patch   # or minor / major
```

`npm version` bumps `package.json`, runs `scripts/sync-version.sh` to mirror the
version into `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`,
commits, tags `vX.Y.Z`, and pushes with the tag. The pushed tag triggers
`.github/workflows/release.yml`, which verifies the tag matches `package.json`,
creates a GitHub Release with generated notes, and publishes to npm (for `pi
install`) when the `NPM_TOKEN` repo secret exists.

Claude Code and Codex install straight from the Git repo, so nothing else is
published; the tag is the release.

Versioning: **patch** = wording or fixes inside a skill, **minor** = new skill
or agent, **major** = removed or renamed skill (breaks anyone invoking it).
