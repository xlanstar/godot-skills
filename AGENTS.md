# godot-skills

Agent skills for Godot 4.7+

## Features

- Token efficient, lightweight

## Rules

- Target Godot 4.7+ and GDScript only; never include C# guidance.
- Assume frontier models already know general programming, common Godot concepts, and how to reason through ordinary tasks. Do not restate that knowledge.
- Include only high-value recall gaps: recent version changes, easily confused syntax or APIs, exact signatures and constraints, similarly named methods or nodes, and non-obvious implementation choices.
- Prefer precise rules, contrasts, and short canonical examples over explanations. Every section must change a model's likely output; delete anything merely educational, inferable, or "nice to know."
- Verify every version-specific claim against the official Godot documentation. State the applicable version when behavior differs across releases; do not guess.
- Keep each `SKILL.md` focused, non-overlapping, and under 2000 tokens. Avoid tutorials, broad reference material, duplicated guidance, exhaustive API lists, and speculative edge cases.
- Agents define task boundaries, expected outputs, and which skills apply. Skills contain reusable Godot knowledge; do not duplicate that knowledge in agents.
