---
name: godot-character-body
description: "Write, edit, or review CharacterBody2D or CharacterBody3D movement."
---

# Character movement

Target Godot 4.7+.

- Call `move_and_slide()` from `_physics_process()`, never `_process()`; it moves from `velocity` and applies the physics step's `delta` automatically.
- Keep `velocity` in units per second (pixels in 2D, typically meters in 3D): use `velocity = direction * speed`, not `velocity = direction * speed * delta`. Apply acceleration and gravity with `delta` instead.
- `move_and_slide() -> bool` reports whether a collision occurred; never assign its return value to `velocity`. A slide collision can rewrite `velocity`, so save the pre-collision value when later logic needs it.
- `is_on_floor()`, `is_on_wall()`, collision counts, and collision getters describe the last `move_and_slide()` call. Before moving they are from the previous physics tick; after moving they describe the current call.
- Floor classification requires `MOTION_MODE_GROUNDED` and uses nonzero `up_direction` plus `floor_max_angle`; `MOTION_MODE_FLOATING` classifies every collision as a wall.
- `floor_snap_length` does not snap while velocity points along `up_direction` (such as during a jump). `apply_floor_snap()` ignores velocity, but does nothing while already on the floor.
- Moving-platform velocity is added automatically. By default, `platform_on_leave` also carries that velocity after departure; do not add either manually unless changing the platform behavior.
