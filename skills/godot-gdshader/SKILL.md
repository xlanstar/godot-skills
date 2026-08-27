---
name: godot-gdshader
description: "Write, edit, or review Godot 4 GDShader code, materials, and shader performance."
---

# GDShader

Target Godot 4.7+. Verify shader-type processor functions, built-ins, render modes, and renderer support against the 4.7 shader reference; they are not interchangeable between `spatial`, `canvas_item`, `particles`, `sky`, and `fog`.

## Recent changes in 4.7

- Spatial shaders expose `IN_SHADOW_PASS` globally; branch on it instead of inferring the shadow pass from other state.
- Spatial `light()` gained an area-light path: `LIGHT_IS_AREA`, `LIGHT_AREA_DIFFUSE_MULTIPLIER`, `LIGHT_AREA_SPECULAR_MULTIPLIER`, and `SPECULAR_AMOUNT`. A `light()` written before 4.7 handles area lights as if they were punctual; branch on `LIGHT_IS_AREA` and use the multipliers there.

## Structure and syntax

- Write Godot shading language, not raw GLSL. Omit `#version`, layouts, and GLSL entry points. Order code as `shader_type`, `render_mode`, uniforms, constants, varyings, custom functions, then processor functions.
- Define custom functions before their callers. Use explicit types and constructors: `2.0` for `float`, `uint(2)` for `uint`; implicit numeric casts are not allowed. Use `snake_case` identifiers and `CONSTANT_CASE` constants.
- Put uniform hints before defaults: `uniform vec4 tint : source_color = vec4(1.0);`. Always mark sRGB color textures with `source_color`; do not use it for linear data such as normal, roughness, metallic, or height maps.
- Use `/** ... */` immediately above a non-obvious uniform to expose an Inspector tooltip. Use `group_uniforms` only when it improves a material's Inspector.
- Assign a `varying` only directly inside `vertex()` or `fragment()`, never in a custom function or `light()`. The default interpolation is `smooth`; use `flat` for discrete values.
- Keep one-off helpers local. Extract `.gdshaderinc` files with `#include` only when multiple shaders actually share code.

## Data flow

- Track coordinate spaces explicitly. Spatial vertex inputs are local by default and spatial fragment normals are view-space; CanvasItem vertices are local pixel coordinates. Use the provided transform matrices rather than ad-hoc conversions.
- In a CanvasItem `fragment()`, input `COLOR` already contains the default texture multiplied by vertex color, `modulate`, and `self_modulate`. Preserve it when that is desired; sample `TEXTURE` explicitly only when raw texels or custom UVs are needed.
- Use `instance uniform` for per-node variation in `canvas_item` and `spatial` shaders instead of duplicating materials.
- `TIME` rolls over after 3,600 seconds by default, follows `Engine.time_scale`, and ignores pause. Drive a global uniform from GDScript when those semantics do not fit.
- With `skip_vertex_transform`, perform every required transform yourself. Writing spatial `POSITION` overrides projection and requires a valid clip-space value on every path. Writing `DEPTH` on any path requires writing it on all paths.
- Read screen, depth, and normal-roughness buffers through declared samplers using `hint_screen_texture`, `hint_depth_texture`, or `hint_normal_roughness_texture` and `SCREEN_UV`. Add `repeat_disable` so edge samples do not wrap, `filter_nearest` when reading the matching pixel, and `filter_linear_mipmap` only when the effect blurs or samples at varying scale.
- Writing spatial `ALPHA`, even conditionally, moves the material to the transparent pipeline with its sorting, shadow, and screen-texture limitations. Avoid it for opaque materials.

## Cost and compatibility

- Prefer `CanvasItemMaterial`, `StandardMaterial3D`, and `WorldEnvironment` features when they express the effect; write a custom shader only for behavior they cannot provide.
- Write only the material outputs the effect needs; Godot removes unused functionality. Do not define `light()` unless replacing the built-in lighting behavior.
- Avoid `discard` unless clipping is required; it defeats the depth prepass. Move per-fragment work into `vertex()` only when linear interpolation preserves the result.
- Do not add precision qualifiers speculatively; conversions and mobile drivers can erase the benefit.
- Godot 4.4+ exposes `CURRENT_RENDERER`, `RENDERER_COMPATIBILITY`, `RENDERER_MOBILE`, and `RENDERER_FORWARD_PLUS` to the shader preprocessor. Branch on them only for real renderer differences.
