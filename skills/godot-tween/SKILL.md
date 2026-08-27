---
name: godot-tween
description: "Write, debug, or review Godot Tween sequences: property/method/callback tweening, parallel steps, looping, and lifetime."
---

# Tween animation

Target Godot 4.7+.

## Lifetime

- `Tween` is one-shot: it auto-starts on the next frame and goes invalid once finished or killed. There is no replay — build a new one per playback.
- Two live tweens on one property both keep writing it and the newest-created one wins the final value, so kill before rebuilding:

```gdscript
var _tween: Tween

func flash() -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
```

- `Node.create_tween()` binds to that node: it halts while the node is outside the tree and dies with it. `get_tree().create_tween()` is unbound and outlives the animated node until `kill()` — add `.bind_node(self)` unless that is deliberate.
- Guard `create_tween()` in `_process()`/`_physics_process()`; unguarded it appends a new tween every frame.
- `is_valid()` means "still in the scene tree", not "unfinished"; `is_running()` means "not paused and not finished".

## Sequencing

- Tweeners run sequentially by default. `parallel()` merges the next tweener into the previous step; `set_parallel(true)` does that for every following tweener until `chain()`. Both also pull in the tweener added _immediately before_ them.

```gdscript
var tween := create_tween().set_parallel()
tween.tween_property(self, "position", target, 0.4)
tween.tween_property(self, "modulate:a", 0.0, 0.4)   # simultaneous
tween.chain().tween_callback(queue_free)             # after both
```

## Tweeners

- `tween_property(object, property, final_val, duration)` — `property` takes a component path (`"position:x"`, `"modulate:a"`).
- The start value is read **when that tweener starts**, not when it is created. `.from(value)` overrides it, `.from_current()` re-reads the live value at start, `.as_relative()` makes `final_val` an offset.
- `tween_method(callable, from, to, duration)` for anything without a property; plus `tween_callback(callable)`, `tween_interval(seconds)`, and `tween_subtween(tween)` to nest a prebuilt tween as one step.
- Godot 4.7: `tween_await(signal)` holds the sequence until the signal fires; add `.set_timeout(seconds)` when emission is not guaranteed.
- `set_trans()`/`set_ease()`/`set_delay()` on the `Tween` set defaults for its tweeners; the same calls on a returned tweener override them for that tweener alone.

## Timing and pausing

- Default process mode is `TWEEN_PROCESS_IDLE`. Use `set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)` when tweening physics-body state so updates land in the physics step.
- Default pause mode is `TWEEN_PAUSE_BOUND` (follows the bound node's `process_mode`); pause-menu tweens need `TWEEN_PAUSE_PROCESS` to survive `SceneTree.paused`.
- `set_speed_scale()` scales the tween alone; `set_ignore_time_scale(true)` detaches it from `Engine.time_scale`.
- `set_loops()` with no argument loops forever. Give every iteration real duration — a zero-duration looped sequence is force-stopped after a few loops.

## Signals

- `finished` is never emitted by an infinitely looping tween.
- `loop_finished(loop_count)` skips the final loop; use `finished` for that one.
- `step_finished(idx)` fires per step, and a parallel group is one step.
- Every `Tweener` also has its own `finished`, so a mid-sequence step is awaitable: `await create_tween().tween_interval(2.0).finished` is the idiomatic timed wait.

## Manual interpolation

`Tween.interpolate_value(initial_value, delta_value, elapsed_time, duration, trans, ease)` is static — hand-driven easing with no tween object. `delta_value` is `final - initial`, not the final value.
