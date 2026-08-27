---
name: godot-multimesh
description: "Draw thousands to millions of copies of one mesh in a single draw call with MultiMesh in Godot: setup order, per-instance color/custom data, buffer updates, culling limits, and when not to use it."
---

# MultiMesh

Target Godot 4.7+.

## When it applies

Same `Mesh` + same material, repeated many times. Hundreds → plain nodes are fine. Thousands with per-object logic → `RenderingServer` instances directly. Hundreds of thousands to millions → MultiMesh. Instances differ only by transform, one `Color`, and one 4-float custom value.

MultiMesh has **no collision, no per-instance visibility, no per-instance script**. Physics needs separate bodies (`PhysicsServer3D` shapes). Culling, shadow settings, LOD, and visibility ranges apply to the whole `MultiMeshInstance3D`, all-or-none — split the world into several MultiMeshes per region instead.

## Setup order is mandatory

`instance_count` clears and resizes the buffers; format and flags set *after* it are silently ignored. Set them first:

```gdscript
extends MultiMeshInstance3D

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D  # default is TRANSFORM_2D (0)
    multimesh.use_colors = true         # only settable while instance_count <= 0
    multimesh.use_custom_data = true
    multimesh.mesh = BoxMesh.new()
    multimesh.instance_count = 10000    # allocate the maximum ever needed
    multimesh.visible_instance_count = 1000  # -1 = draw all

    for i in multimesh.visible_instance_count:
        multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(i * 20, 0, 0)))
```

To change a flag later, set `instance_count = 0`, change it, then resize again (all data is lost).

Standard pooling pattern: allocate once at max, then move only `visible_instance_count` — it never reallocates. Keep live instances packed at the front of the buffer.

`custom_aabb` — set it manually to skip costly runtime AABB recalculation; `get_aabb()` returns the computed local-space box.

## Per-instance data

- `set_instance_transform(i, Transform3D)` / `set_instance_transform_2d(i, Transform2D)` — must match `transform_format`.
- `set_instance_color(i, Color)` — needs `use_colors = true` **and** `BaseMaterial3D.vertex_color_use_as_albedo = true`. It *multiplies* existing vertex colors, so set albedo to `Color(1, 1, 1)` for an absolute color.
- `set_instance_custom_data(i, Color)` — a `Color` only as a container for 4 floats. Needs `use_custom_data = true`; read it in a shader as `INSTANCE_CUSTOM`.
- Forward+/Mobile store color and custom data at 32 bits per component; **Compatibility packs them to 16 bits**.
- `transform_array`, `transform_2d_array`, `color_array`, `custom_data_array` are deprecated — reading or writing them is very slow.

## Bulk updates

Per-instance setters are one call each. For thousands updated per frame, build a `PackedFloat32Array` and assign `multimesh.buffer` in one go (`RenderingServer.multimesh_set_buffer()` from a thread/GDExtension for the extreme case). Per-instance stride: 12 floats for `TRANSFORM_3D` (three rows of 4: basis row + origin component), 8 for `TRANSFORM_2D`, then +4 for color and +4 for custom data when enabled. Getting `buffer` returns a **copy** — mutating the returned array does nothing.

Better still: keep the transforms constant and do the movement in the vertex shader using `INSTANCE_ID` / `INSTANCE_CUSTOM`, feeding bulk data through a float-format `Image`/texture.

## Physics interpolation

With interpolation on, use `set_buffer_interpolated(buffer_curr, buffer_prev)` when instance order changes between physics ticks (particle-like reuse); plain `buffer` interpolates correctly only when order is stable. Call `reset_instance_physics_interpolation(i)` (or `reset_instances_physics_interpolation()`) after teleporting/spawning, or the instance streaks in from its old position. `physics_interpolation_quality`: `INTERP_QUALITY_FAST` (Basis lerp, default) is fine except at very low tick rates or fast rotation, where `INTERP_QUALITY_HIGH` (slerp) avoids warping.
