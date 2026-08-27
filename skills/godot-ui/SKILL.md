---
name: godot-ui
description: "Build, debug, or review responsive Godot Control layouts, sizing, and themes."
---

# Godot UI

Target Godot 4.7+.

## Container layout

- A `Container` arranges its direct `Control` children and overwrites manual rectangle changes when it sorts them. Configure the container and per-axis size flags; insert a non-`Container` wrapper for independently placed descendants.
- `SIZE_EXPAND` claims surplus space; `SIZE_FILL` stretches within the allocated slot. Shrink flags align instead, and `size_flags_stretch_ratio` only weights expanding siblings.
- Prefer content-derived minimum sizes. Use `custom_minimum_size` only as a hard floor.
- Godot 4.7: `custom_maximum_size` defaults to `Vector2(-1, -1)` (unbounded); a positive axis caps that axis, and maximum size takes priority over minimum size. Use `get_bound_minimum_size()`, not `get_combined_minimum_size()`, when a cap applies.
- For dynamic intrinsic constraints, override `_get_minimum_size()` or 4.7's `_get_maximum_size()`. Call `update_minimum_size()` after a minimum change or `update_maximum_size()` after a maximum change; the latter also invalidates minimum-size caches. These virtuals are not called when the script is attached to a built-in subtype that already overrides the corresponding size.

## Anchors and responsiveness

- Anchors are parent-relative ratios; offsets are pixel distances from them. Use them only under a non-`Container` parent. To reset both together, use `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` rather than changing anchors while leaving stale offsets.
- Leave `layout_direction` at `LAYOUT_DIRECTION_INHERITED` so forced or locale-derived parent direction propagates. Application-locale RTL requires a valid translation for that locale (or the configured fallback).

## Theme

- A `Theme` propagates only through an uninterrupted chain of `Control` or `Window` descendants. A child theme merges with inherited items and wins where it defines the same item.
- Use theme type variations for reusable semantic variants and per-node overrides only for one-offs. Custom controls should read items through `get_theme_*()`.
- Refresh cached theme-derived values on `NOTIFICATION_THEME_CHANGED`; it is also sent when the node enters the scene tree.
