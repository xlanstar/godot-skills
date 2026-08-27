---
name: godot-gdscript
description: "Write, edit, or review GDScript."
---

# GDScript

Target Godot 4.7+. Verify unfamiliar syntax and virtual method signatures against the 4.7 class reference.

## Recent changes

- `@abstract` classes and methods were introduced in 4.5. Abstract methods have no body; subclasses must implement every abstract method or also be abstract.
- Variadic functions were introduced in 4.5: `func emit_all(...args: Array) -> void`. The rest parameter must be last, cannot have a default, and cannot use `Array[T]`. GDScript has no spread-call syntax; use `callv()` for an argument array.

## Required idioms

Statically type every variable, parameter, return, and container; untyped code falls back to `Variant` dispatch. Also use `&"name"` for repeated identifiers, `preload()` for fixed paths, `@onready` or cached references over repeated `get_node()`, signals or groups over polling, packed arrays for bulk buffers, integer vectors for grid data, and static methods when no instance state is needed. Allocate nothing per frame.

## Callbacks

Match virtual methods to the class reference exactly; never change parameter count, names, types, or return type. Processing for `_process`, `_physics_process`, `_input`, `_shortcut_input`, `_unhandled_key_input`, and `_unhandled_input` is enabled automatically when the method is overridden; the matching `set_process_*()` call only toggles it afterwards.

Lifecycle order:

- `_enter_tree()` runs parent first, then children. `_ready()` is the reverse: children first, parent last. `_exit_tree()` runs children first, so a node's own `_exit_tree()` is last.
- `_ready()` fires once per node; re-adding a removed node does not repeat it unless `request_ready()` was called first.
- `_init()` runs outside the tree: no `@onready`, no `get_node()`. A parameterized `_init()` forces every `.new()` call to pass those arguments.
- `_process(delta)` and `_physics_process(delta)` run in ascending `process_priority` / `process_physics_priority`, ties in tree order.

Input, in the order one event visits the callbacks:

`_input()` -> `Control._gui_input()` -> `_shortcut_input()` -> `_unhandled_key_input()` -> `_unhandled_input()`

- The non-GUI callbacks visit nodes in reverse depth-first order: deepest node first, root last.
- Consume an event with `get_viewport().set_input_as_handled()`; inside `_gui_input()` use `accept_event()`.
- `_gui_input()` requires `mouse_filter` other than `MOUSE_FILTER_IGNORE`, and only the targeted Control and its ancestors receive mouse events. GUI keyboard and joypad events do not travel up the tree; unconsumed ones resurface in `_unhandled_input()`.
- Prefer `_unhandled_key_input()` over `_unhandled_input()` for key handling: unrelated events such as `InputEventMouseMotion` are filtered out.

Other:

- `_draw()` runs only after `queue_redraw()`, and the `draw_*` methods are valid only inside it.
- `_notification(what: int)` is the only hook for notifications without a dedicated virtual, such as `NOTIFICATION_WM_CLOSE_REQUEST`, `NOTIFICATION_THEME_CHANGED`, and `NOTIFICATION_PREDELETE`.

## `await`

- `await` on a signal or coroutine makes the enclosing function a coroutine, so every caller that needs its return value must `await` it too.
- Calling a coroutine without `await` runs it asynchronously and leaves the caller a normal function, but reading its return value is an error.
- Returning a signal from a non-coroutine function makes the caller's `await` wait on that signal.
- After resumption, recheck referenced objects with `is_instance_valid()`, tree membership with `is_inside_tree()`, and the state or generation that started the work. Guard re-entrant coroutines with a busy flag or generation ID.
