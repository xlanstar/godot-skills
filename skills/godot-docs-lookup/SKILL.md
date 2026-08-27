---
name: godot-docs-lookup
description: "Look up official Godot API or tutorial documentation to verify a signature, parameter, enum, or version-specific behavior."
---

# Documentation lookup

Target Godot 4.7+. Fetch the raw reStructuredText behind docs.godotengine.org instead of the HTML page — same content, ~30x smaller (43 KB vs 1.4 MB for `CharacterBody3D`), and greppable.

## URL shape

```
https://docs.godotengine.org/en/<version>/_sources/<page path>.rst.txt
```

- `<version>`: pin `4.7` (also valid: `4.6`, `stable`, `latest`). Pin when the answer is version-sensitive.
- Class reference: `classes/class_<lowercased class name>.rst.txt` — `CharacterBody3D` → `class_characterbody3d`, `RenderingServer` → `class_renderingserver`.
- Tutorials: mirror the HTML path — `https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html` → `_sources/tutorials/physics/using_character_body_2d.rst.txt`.

## Extract one member, not the whole class

Class pages run 20–60 KB. Anchors are stable, so slice out only the member in question:

```bash
# anchor forms: _class_<Class>_method_<name>:  _property_<name>:  _signal_<name>:  _constant_<NAME>:
curl -sL https://docs.godotengine.org/en/4.7/_sources/classes/class_characterbody3d.rst.txt \
| awk '/_class_CharacterBody3D_method_move_and_slide:/{f=1} f{print; if(++n>18) exit}'
```

Class name keeps its original casing in the anchor even though the filename is lowercase.

For a signature-only sweep, grep the method lines:

```bash
curl -sL https://docs.godotengine.org/en/4.7/_sources/classes/class_tween.rst.txt | grep '^:ref:.*\*\*\\ ('
```

## Reading the RST

- Signatures render as `:ref:`bool<class_bool>` **move_and_slide**\ (\ )` — the `:ref:` wrappers are link markup; the type is inside the backticks.
- Method qualifiers appear as `|virtual|`, `|const|`, `|static|`, `|vararg|` after the signature.
- `.. rst-class:: classref-*` lines are section separators (`classref-method`, `classref-property`, `classref-signal`) — useful as awk boundaries.
- The trailing `.. |virtual| replace::` block at the end of every page is boilerplate; ignore it.

## When to use

Look it up rather than recall it for: exact parameter order and defaults, enum constant names, `@export` annotation forms, and anything the user frames as "did this change in 4.x". A 404 on a class page usually means the class was renamed — check the release notes rather than guessing a near-miss name.
