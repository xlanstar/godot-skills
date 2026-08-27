---
name: godot-input
description: "Implement or debug Godot input actions, event routing, UI focus/navigation, and pointer input."
---

# Input Handling

Target Godot 4.7+.

## Actions and event routing

- Poll `Input` for held state; use the callback's `InputEvent` for discrete transitions. `Input.get_vector()` orders actions as negative X, positive X, negative Y, positive Y.
- `event.is_action_pressed(action, allow_echo = false, exact_match = false)` already rejects key echo by default. The second positional boolean enables echo; use a named argument when setting `exact_match`.
- Handle gameplay in `_unhandled_input()` so GUI gets first refusal. Use `_shortcut_input()` for key, shortcut, and joypad-button shortcuts; reserve pre-GUI `_input()` for global interception.
- Runtime `InputMap` changes are not saved automatically; persist user bindings separately. Keep built-in `ui_*` actions for UI navigation, never gameplay.

## UI focus

- Custom keyboard/controller targets need `FOCUS_ALL`, not `FOCUS_CLICK`; decoration uses `FOCUS_NONE`. In Godot 4.7, `FOCUS_ACCESSIBILITY` is focusable only while a screen reader is active.
- On opening a screen, call `grab_focus.call_deferred()` on its first meaningful control; restore focus to the opener when a modal closes.
- `focus_neighbor_*` controls directional navigation; `focus_next`/`focus_previous` control Tab order. Leave paths unset for Godot's automatic best guess; set only ambiguous routes.
- Keep a visible focus style and a mouse-free path through every operation. For an inactive subtree, set `focus_behavior_recursive` to `FOCUS_BEHAVIOR_DISABLED` and leave descendants `FOCUS_BEHAVIOR_INHERITED`; `FOCUS_BEHAVIOR_ENABLED` explicitly bypasses an ancestor override.

## Pointer input

- `MOUSE_FILTER_STOP` receives and blocks; `MOUSE_FILTER_PASS` receives and bubbles unhandled events to Control ancestors, not Controls behind it; `MOUSE_FILTER_IGNORE` neither receives nor blocks Controls behind it.
- Handle Control-owned events in `_gui_input()` and call `accept_event()` only when consumed. For non-Control callbacks, use `get_viewport().set_input_as_handled()`; neither API changes `Input` polling state.
- When a child's `mouse_filter` appears ignored, check `get_mouse_filter_with_override()`: an ancestor's `MOUSE_BEHAVIOR_DISABLED` makes inheriting descendants effectively `IGNORE`, while `MOUSE_BEHAVIOR_ENABLED` explicitly bypasses that override.
