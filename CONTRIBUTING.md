# Contributing

Thanks for helping improve godot-skills. This plugin is only skills, agents,
and manifests — no runtime code, no dependencies. Keep it that way.

See [README.md](README.md) for install and release instructions.

## What belongs here

A skill earns its place only if a frontier model would otherwise get it wrong.
Before writing, ask: would the model already produce this from general
knowledge? If yes, don't write it.

Good candidates:

- Godot 4.7+ API changes, renames, and removals
- Easily confused methods or nodes (`move_and_slide` vs `move_and_collide`)
- Exact signatures, parameter order, enum values, and hard constraints
- Non-obvious implementation choices with a clear correct answer

Not candidates: tutorials, general programming, broad API reference,
speculative edge cases, or anything already covered by another skill.

GDScript only. Never add C# guidance.

## Adding a skill

1. Create `skills/<name>/SKILL.md`. Name it `godot-<topic>`, kebab-case,
   matching the directory name.
2. Start with YAML frontmatter:

   ```yaml
   ---
   name: godot-tween
   description: "Write, debug, or review Godot Tween sequences: property/method/callback tweening, parallel steps, looping, and lifetime."
   ---
   ```

   The description is what the host matches against a user's task, so write it
   as the situations that should trigger the skill, not as a topic label.
3. Open with `# Title` and `Target Godot 4.7+.`
4. Write precise rules, contrasts, and short canonical examples. Every section
   must change the model's likely output — delete anything merely educational.
5. Verify every version-specific claim against the official Godot
   documentation. State the applicable version when behavior differs across
   releases. Do not guess.
6. Stay under 2000 tokens:

   ```sh
   ./scripts/count-skill-tokens.sh
   ```

Full authoring rules live in [AGENTS.md](AGENTS.md).

## Adding an agent

`agents/<name>.md` defines task boundaries, expected outputs, and which skills
apply. Agents must not repeat Godot knowledge that belongs in a skill.

## Pull requests

- One skill or one focused change per PR.
- Say which Godot version you verified against, and link the docs page for any
  version-specific claim.
- Don't bump versions or edit manifests — `npm version` handles that at release
  time.
- Note in the PR description whether the change is patch (wording or fixes),
  minor (new skill or agent), or major (removed or renamed skill).
