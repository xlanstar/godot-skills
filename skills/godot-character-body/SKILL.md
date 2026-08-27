---
name: godot-character-body
description: "Write, edit, or review CharacterBody2D or CharacterBody3D."
---

# Character Body

Target Godot 4.7+.

## Moving

- Move only with `move_and_slide()` or `move_and_collide()`, called from `_physics_process()`; never assign `position`/`global_position` to move a body, and never move from `_process()`.
- `move_and_slide()` moves from `velocity` and applies the physics `delta` itself. `move_and_collide(motion)` takes an absolute motion vector, so it needs `velocity * delta`. Mixing these up is the common bug.
- Keep `velocity` in units per second (pixels in 2D, meters in 3D): `velocity = direction * speed`, not `direction * speed * delta`. Apply acceleration and gravity with `delta`.
- Gravity: `velocity += get_gravity() * delta`, which honors project gravity and `Area2D`/`Area3D` overrides at the body's position; do not hardcode a constant.

## Collision response

- `move_and_slide() -> bool` reports whether a collision occurred; never assign its return value to `velocity`. It rewrites `velocity` on collision (for example zeroing the vertical component on landing), so save the pre-collision value when later logic needs it.
- `move_and_collide(motion)` stops dead at the first collision and returns a `KinematicCollision2D`/`3D` or `null`. It never touches `velocity`; write the response yourself:
  ```gdscript
  var collision = move_and_collide(velocity * delta)
  if collision:
      velocity = velocity.slide(collision.get_normal())  # or .bounce() to reflect
  ```
- Use `move_and_collide(motion, true)` (`test_only`) to probe a move without applying it.
- Iterate slide collisions with `for i in get_slide_collision_count(): get_slide_collision(i)`. The count only includes collisions that redirected the body, not every touching body — use an `Area` or shape query for contact detection.
- `is_on_floor()`, `is_on_wall()`, collision counts, and collision getters describe the last `move_and_slide()` call. Before moving they are from the previous physics tick; after moving they describe the current call.

## Surface classification

- Floor/wall/ceiling classification requires `MOTION_MODE_GROUNDED` and uses nonzero `up_direction` plus `floor_max_angle` (default 45°); `MOTION_MODE_FLOATING` classifies every collision as a wall and disables slope handling.
- `floor_stop_on_slope` (default `true`) keeps a still body from sliding down slopes. `wall_min_slide_angle` (default 15°) is the minimum angle before the body slides along a wall instead of stopping.
- `floor_snap_length` does not snap while velocity points along `up_direction` (such as during a jump). `apply_floor_snap()` ignores velocity, but does nothing while already on the floor.
- Moving-platform velocity is added automatically. By default, `platform_on_leave` also carries that velocity after departure; do not add either manually unless changing the platform behavior.
