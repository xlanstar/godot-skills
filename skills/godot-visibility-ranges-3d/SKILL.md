---
name: godot-visibility-ranges-3d
description: "Set up manual/hierarchical LOD (HLOD) in Godot with visibility ranges: begin/end distances and margins, fade modes and their Forward+-only limitation, visibility_parent dependency trees, and the dithering alternative."
---

# Visibility ranges (HLOD)

Target Godot 4.7+.

Manual LOD on any `GeometryInstance3D` — `MeshInstance3D`, `MultiMeshInstance3D`, `GPUParticles3D`, `CPUParticles3D`, `Label3D`, `Sprite3D`, `AnimatedSprite3D`, `CSGShape3D` — so levels can change node type (mesh up close, `Sprite3D` impostor far away).

Pick this over automatic **mesh LOD** when levels are artist-authored, when one merged node should replace a group of nodes (fewer draw calls at distance, per-node culling up close), or to fade objects out entirely (distant `Label3D`s). Both can run on the same mesh.

## Properties

All on `GeometryInstance3D`; distance is camera → **center of the instance's AABB**, in 3D units:

- `visibility_range_begin` — hidden when *closer* than this. `0.0` disables the check.
- `visibility_range_end` — hidden when *farther* than this. `0.0` disables the check.
- `visibility_range_begin_margin` / `visibility_range_end_margin` — hysteresis or fade distance, meaning depends on fade mode. `0.0` makes fade mode irrelevant.
- `visibility_range_fade_mode`.

Center-of-AABB, not screen space: unlike mesh LOD's `threshold_pixels`, these distances are **not** compensated for FOV or viewport resolution, and a large mesh switches based on its center even when its near edge is right in front of the camera. Split oversized meshes.

Two nodes, sphere up close and box beyond 10 units, with 1 unit of hysteresis:

```gdscript
$Sphere.visibility_range_end = 10.0
$Sphere.visibility_range_end_margin = 1.0
$Box.visibility_range_begin = 10.0
$Box.visibility_range_begin_margin = 1.0
```

## Fade modes

- `VISIBILITY_RANGE_FADE_DISABLED` (default) — instant switch, margins act as hysteresis so the LOD does not flip back and forth at the boundary. Fastest; stays opaque.
- `VISIBILITY_RANGE_FADE_SELF` — alpha-fades *itself* out at its own range limits.
- `VISIBILITY_RANGE_FADE_DEPENDENCIES` — alpha-fades in its `visibility_parent` dependents instead. Identical to `SELF` unless a dependency tree exists.

Both fade modes force transparent rendering during the transition — a real cost, and subject to [transparency sorting](https://docs.godotengine.org/en/latest/tutorials/3d/3d_rendering_limitations.html) glitches.

**Forward+ only.** On Mobile and Compatibility they behave like `DISABLED` *with hysteresis disabled* — so a project targeting mobile gets harder popping from a fade mode than from leaving it off. Prefer `DISABLED` with margins there.

## visibility_parent

`visibility_parent` is a `NodePath` on **Node3D**, so it applies to that node *and all its descendants*. Target must be a `GeometryInstance3D`; it need not be an actual scene-tree parent, but pointing at a descendant is a dependency cycle and errors in the Output panel.

Dependents are visible only while the parent (and every ancestor in the chain) is hidden by being closer than its own `visibility_range_begin`. So for a `BatchOfHouses` mesh replacing `House1..4` at distance, configure only two things: `visibility_range_begin` on `BatchOfHouses`, and `visibility_parent` on the houses — no `visibility_range_end` on each house to keep in sync.

Setting `visible = false` removes a node from the dependency tree entirely: its dependents then ignore its `visibility_range_begin` and stay visible.

## Dithering instead of alpha

Cheaper than alpha fade and free of sorting glitches, at the cost of a visible noise pattern (hidden well by TAA or high resolution). Two LODs only, since `BaseMaterial3D.distance_fade` fades either near or far, not both:

- Margins `0.0` on both nodes; extend the ranges by the fade distance instead — *decrease* `visibility_range_begin`, *increase* `visibility_range_end` — or the dither never shows.
- Near material: `distance_fade` = **Object Dither**, `distance_fade_min_distance` = its `visibility_range_end`, `distance_fade_max_distance` = that minus the fade distance.
- Far material: **Object Dither**, min = its `visibility_range_begin`, max = that plus the fade distance.

## Cheaper distant materials

LOD meshes cut vertices, not per-pixel shading, which is the usual GPU bottleneck. On distant LOD materials disable Normal Map (especially mobile), Rim, Clearcoat, Anisotropy, Height, Subsurface Scattering, Back Lighting, Refraction, Proximity Fade. Measure: each *unique* material has its own cost, so the trade is not automatically a win.
