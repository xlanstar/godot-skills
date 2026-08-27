---
name: godot-mesh-lod-3d
description: "Set up and tune automatic 3D mesh LOD in Godot: which imports generate LODs, the pixel threshold and per-object bias, MultiMeshInstance3D/particles caveats, and when to use visibility ranges instead."
---

# Mesh LOD

Target Godot 4.7+.

Godot decimates imported meshes with meshoptimizer and swaps levels automatically. Works on any node that draws meshes: `MeshInstance3D`, `MultiMeshInstance3D`, `GPUParticles3D`, `CPUParticles3D`.

Use automatic mesh LOD for decimating a single mesh. Use **visibility ranges (HLOD)** instead when the levels are artist-authored, or when you need to swap a group of nodes for one merged node.

## Getting LODs generated

Imported 3D **scenes** (glTF, `.blend`, Collada, FBX) generate LODs by default — nothing to configure.

**OBJ does not.** OBJ imports as a bare mesh resource, not a scene. Select the file → Import dock → **Import As: Scene** → **Reimport**, then restart the editor.

Turn LODs off per-mesh in Advanced Import Settings (**Generate LODs**) when decimation breaks a mesh — skinned meshes are the usual offender — or to cut import time.

## Tuning

Global threshold: `rendering/mesh_lod/lod_change/threshold_pixels`, default `1`. That default is tuned to be perceptually lossless; raise it to trade quality for performance. It is a **per-viewport** property at runtime, not a global:

```gdscript
get_tree().root.mesh_lod_threshold = 4.0
```

Per-object, `lod_bias` on any `GeometryInstance3D`:

- `> 1.0` — transitions happen later: higher quality, lower performance.
- `< 1.0` — transitions happen sooner: lower quality, higher performance.

`ReflectionProbe` has its own `mesh_lod_threshold`. Raise it for probes with `update_mode = UPDATE_ALWAYS`.

Selection is screen-space, so camera FOV and viewport resolution are already accounted for — unlike visibility ranges, which need manual compensation.

## MultiMesh and particles

LOD is chosen from the point of the **node's AABB** closest to the camera, so every instance in one `MultiMeshInstance3D` or particle node renders at the **same** LOD level.

Split instances that are far apart into separate `MultiMeshInstance3D` nodes. This also lets frustum and occlusion culling drop whole nodes — neither can cull individual instances inside a MultiMesh.

If a `GPUParticles3D` picks the wrong level, its visibility AABB is probably wrong: select the node and use **GPUParticles3D > Generate AABB** in the 3D viewport toolbar.

## Verifying

Viewport camera menu → **Display Advanced… > Disable Mesh LOD** to A/B it. Enable **View Information** and watch the primitive count drop, and **View Frame Time** for FPS — FPS won't move if you are CPU-bound.

To watch decimation itself: **Display Wireframe**, then drag `threshold_pixels`.
