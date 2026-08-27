---
name: godot-occlusion-culling-3d
description: "Set up and debug 3D occlusion culling in Godot: OccluderInstance3D baking rules, what is silently excluded from bakes, occludee requirements, runtime toggling, and why an object is or isn't culled."
---

# Occlusion culling

Target Godot 4.7+.

## Decide before setting it up

Occlusion is CPU-rasterized into a low-resolution buffer (Embree) and an occludee is culled only when its **AABB is fully covered** by occluder shapes. Consequences: small occludees cull easily, large ones rarely; few large occluders (walls, floors, terrain ridges) beat many small ones (props).

Gain is largest on the **Mobile** renderer — it is the only method without a depth prepass, so culling removes real shading overdraw. **Forward+** and **Compatibility** both prepass, so the win there is draw calls and vertices only. Open scenes with few blockers may not pay back the CPU cost.

Level layout matters more than any setting: interiors need opaque walls breaking line of sight at regular intervals, and open scenes cull best with pyramid-like elevation. A flat open map has nothing to occlude with.

Not supported in **Web** exports by default — it needs a custom export template built with `module_raycast_enabled=yes`. Otherwise the whole setup silently does nothing.

## Enabling

Project setting `rendering/occlusion_culling/use_occlusion_culling` (Advanced toggle in the dialog). Applies immediately, no editor restart. The root viewport needs that project setting on; every other Viewport has its own `use_occlusion_culling` and is toggled per-viewport:

```gdscript
get_tree().root.use_occlusion_culling = true
```

Nothing is culled until occluders exist — visible geometry is never used automatically.

## Baking (default path)

Add `OccluderInstance3D`, press **Bake Occluders**; it stores an `Occluder3D` resource drawn as purple wireframe (needs **View Gizmos**).

Silently **excluded from bakes**:

- Everything that is not a `MeshInstance3D` — `MultiMeshInstance3D`, `GPUParticles3D`, `CPUParticles3D`, CSG nodes. Since 4.4, a CSG node converted to a MeshInstance3D beforehand does bake.
- Surfaces with a **transparent material**, even when the texture is fully opaque.
- Meshes whose `VisualInstance3D.layers` fall outside `bake_mask`.

These limits apply to occluders only; any `GeometryInstance3D` can be an occludee.

Dynamic objects (player, enemies, doors) must be kept out of the bake or they occlude from their editor position forever. Standard setup: put them on visual layer 2, clear layer 2 in `bake_mask` (it defaults to all layers on), rebake. Equivalent, as editor-time setup — changing these at runtime does nothing to an existing bake:

```gdscript
$Enemy/MeshInstance3D.set_layer_mask_value(1, false)
$Enemy/MeshInstance3D.set_layer_mask_value(2, true)
$OccluderInstance3D.set_bake_mask_value(2, false)
```

Bakes are static snapshots: **rebake after moving level geometry**.

`bake_simplification_distance` (Bake > Simplification) trades accuracy for CPU cost. Default `0.1` is already fairly aggressive; `0.01` is perceptually unaffected; `0.0` disables simplification (vertices are still merged and the mesh re-indexed). Raise it when complex scenes stutter; too high produces occluders that swallow geometry and cull visible objects.

## Manual occluders

Set `occluder` on an `OccluderInstance3D` to `QuadOccluder3D`, `BoxOccluder3D`, `SphereOccluder3D`, or `PolygonOccluder3D`. `ArrayOccluder3D` has no editor handles and exists for procedural generation from script. This is the workaround for MultiMesh/particles/CSG.

## Movement

Moving an `OccluderInstance3D` — or any parent — rebuilds the BVH each frame. Never animate one. Toggling `visible` costs a single update instead, so for a door: parent the occluder outside the door, hide it when the door starts opening, show it when fully closed. If a moving occluder is unavoidable, use a primitive shape, never a baked one.

## Troubleshooting

**Not culled when it should be** — check the bake exclusions above; then on the occludee check `extra_cull_margin` is `0.0` and `ignore_occlusion_culling` is off, and look at the orange AABB gizmo: an oversized AABB is never fully covered.

**Culled when it shouldn't be** — stale bake after geometry moved, dynamic objects baked in, or `bake_simplification_distance` too high. Last resort: enable `ignore_occlusion_culling` on the occludee (correct for first-person view models, which are never occluded anyway).

**Inspecting** — viewport camera menu → **Display Advanced… > Occlusion Culling Buffer** shows the actual buffer; pair with **View Information** to compare draw calls with the setting on and off. Results depend heavily on camera angle.

**Still CPU-bound** after simplification — `rendering/occlusion_culling/bvh_build_quality` and `rendering/occlusion_culling/occlusion_rays_per_thread`.
