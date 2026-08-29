# godot-skills

A efficient and lightweight Agent Skills plugin for Godot 4.7+. Works with Claude Code, Codex CLI, Codex App, Antigravity, OpenCode, Hermes Agent, and Pi Coding Agent.

## Install

### Claude Code

```sh
/plugin marketplace add xlanstar/godot-skills
/plugin install godot-skills@godot-skills
```

If the install summary says `Run /reload-plugins to activate.`, run that command.

### Codex CLI

```sh
codex plugin marketplace add https://github.com/xlanstar/godot-skills
codex plugin add godot-skills@godot-skills
```

### Antigravity

```sh
agy plugin install https://github.com/xlanstar/godot-skills
```

### Codex App, OpenCode, Hermes Agent

These read the cross-agent `.agents/skills/` convention. From your Godot
project root:

```sh
git clone https://github.com/xlanstar/godot-skills.git ~/godot-skills
mkdir -p .agents/skills && ln -s ~/godot-skills/skills/* .agents/skills/
```

Hermes Agent additionally needs the project trusted once: `hermes skills trust .`

### Pi Coding Agent

```sh
pi install npm:@modastar/godot-skills
```

### Local development

Load from a working copy without installing:

```sh
claude --plugin-dir /absolute/path/to/godot-skills          # session only
codex plugin marketplace add /absolute/path/to/godot-skills
agy plugin install /absolute/path/to/godot-skills
pi install /absolute/path/to/godot-skills
```

All hosts discover `skills/*/SKILL.md` automatically.

## Design philosophy

We assume modern frontier LLMs already have sufficient reasoning ability and need minimal guidance. Skills should cover only information the model is unlikely to know or recall accurately, or topics where it may confuse details or be unsure of the correct approach, such as new or easily confused syntax, version-specific APIs, similarly named methods or nodes, or tasks with non-obvious implementation choices.

## Architecture

```text
plugin.json                 Agent Plugins manifest (Cursor, Antigravity)
.claude-plugin/plugin.json  Claude Code metadata
.codex-plugin/plugin.json   Codex CLI plugin metadata
.agents/plugins/marketplace.json  Codex CLI local marketplace entry
package.json                Pi package metadata
AGENTS.md                   Shared instructions (CLAUDE.md symlinks here)
skills/*/SKILL.md           Portable Agent Skills
```

Codex App, OpenCode, and Hermes Agent consume `skills/` through the
`.agents/skills/` convention rather than a manifest.

The plugin intentionally has no hooks, MCP server, runtime code, or dependencies.

## Release

```sh
npm version patch   # or minor / major
```

`npm version` bumps `package.json`, runs `scripts/sync-version.sh` to mirror the
version into `plugin.json`, `.claude-plugin/plugin.json`, and
`.codex-plugin/plugin.json`,
commits, tags `vX.Y.Z`, and pushes with the tag. The pushed tag triggers
`.github/workflows/release.yml`, which verifies the tag matches `package.json`,
creates a GitHub Release with generated notes, and publishes to npm (for `pi
install`) when the `NPM_TOKEN` repo secret exists.

Most hosts install straight from the Git repo, so nothing else is
published; the tag is the release.

Versioning: **patch** = wording or fixes inside a skill, **minor** = new skill
or agent, **major** = removed or renamed skill (breaks anyone invoking it).
