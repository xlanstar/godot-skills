---
name: godot-navigation
description: "Godot 2D/3D navigation agents, path following, avoidance, map synchronization, and navigation baking."
---

# AI Navigation

Target Godot 4.7+. `NavigationAgent2D`/`3D` calculates paths and avoidance; it never moves its parent.

## Path queries and following

- Setting `target_position` (global coordinates) requests a path on navigation regions selected by the agent's `navigation_layers` mask.
- NavigationServer changes synchronize at the end of a physics frame. Do not query in `_ready()` or rely on `call_deferred()` alone: wait one physics frame after setup, wait for `map_changed(map: RID)` for the agent's map, or guard the initial query with `map_get_iteration_id(agent.get_navigation_map()) > 0`.
- In `_physics_process()`, check `is_navigation_finished()` first, then call `get_next_path_position()` exactly once while active. Calling it after completion causes jitter.
- Do not call path-updating methods from agent signal callbacks; they can emit recursively. Use `CONNECT_DEFERRED`, `call_deferred()`, or the next physics tick.
- Do not reset `target_position` every frame. Retarget after meaningful movement or on a timer; frequent repaths can make the first path point alternate around the agent.
- Increase `path_desired_distance`/`target_desired_distance` when speed or update interval lets the actor overshoot them; undersized values cause repath loops.

## Clearance and avoidance

- Path clearance comes from baked `NavigationPolygon.agent_radius`/`NavigationMesh.agent_radius`. `NavigationAgent.radius` affects avoidance only; use separate navigation maps when actor clearances differ.
- Avoidance is optional local steering and uses `avoidance_layers`/`avoidance_mask`, not `navigation_layers`. When enabled, match `max_speed` to the actor, set the agent's desired `velocity` each physics tick, and move the parent only from `velocity_computed(safe_velocity)`.
- Even for avoidance-only use, set `target_position`; otherwise `velocity_computed` returns zero.
- `NavigationAgent3D` defaults to flat XZ avoidance (`use_3d_avoidance = false`); `keep_y_velocity = true` reapplies the requested Y velocity. Full 3D avoidance uses spheres and ignores `height`.

## Runtime baking

- `NavigationRegion2D.bake_navigation_polygon(on_thread: bool = true)` and `NavigationRegion3D.bake_navigation_mesh(on_thread: bool = true)` are threaded by default.
- Wait for `bake_finished`, then for the navigation map to synchronize before querying the replacement data.
