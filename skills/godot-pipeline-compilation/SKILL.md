---
name: godot-pipeline-compilation
description: "Diagnose and remove first-playthrough shader (pipeline) compilation stutter in Godot: precompilation warm-up scenes, the pipeline compilation monitors, and the export Shader Baker."
---

# Pipeline compilation stutter

Target Godot 4.7+ (mechanisms introduced in 4.4/4.5).

## Scope

- Ubershaders and pipeline precompilation exist only in **Forward+ and Mobile** (Vulkan / D3D12 / Metal). **Compatibility** (OpenGL/WebGL) has none of it — there the only fix is the legacy one: show the material/shader/particle in the view frustum for at least one frame during loading.
- Two distinct steps: *shader compilation* = GLSL → intermediate (SPIR-V/DXIL/MIL); *pipeline compilation* = intermediate → GPU pipeline, done on the user's machine, cached by the driver, and wiped when the driver updates. Stutter comes from the pipeline step. Do not test for stutter on a warm driver cache.
- 4.4+ precompiles automatically, but only from evidence the RenderingServer has already seen. Anything first loaded, instanced, or toggled **during gameplay** can still compile then.

## Reading the monitors

Debugger → Monitors → pipeline compilations. Values only ever increase (deleted pipelines are not subtracted). Spikes outside loading screens are the stutters your players will hit.

- **Canvas** — 2D drawing. No precompilation exists for 2D; the first draw of a 2D node always compiles.
- **Mesh** — 3D mesh load. Load meshes on a background thread to hide it. Node-level modifiers such as material overrides are *not* covered here.
- **Surface** — first frame after 3D nodes were added to the tree, visible or not. A gameplay spike here almost always means a rendering feature was not enabled early enough (see below).
- **Draw** — an ubershader was missing at draw time. Should never happen; report it upstream with a minimal reproduction project.
- **Specialization** — background optimization. Cannot stutter; many per frame can cost framerate.

## Warm up rendering features early

Precompilation only enables a feature's pipeline variants for meshes/surfaces created *after* the feature is first seen. Put a trivial scene that uses every feature the game needs **before** the bulk of assets load — offscreen is fine (behind a `ColorRect`, or a `SubViewport` outside the window).

Features that must be seen first: 3D MSAA level, `ReflectionProbe`, separate specular (subsurface scattering, compositor effects sampling specular), motion vectors (TAA, FSR2, motion blur), normal/roughness (SDFGI, VoxelGI, SSR, SSAO, SSIL, `normal_roughness_buffer` in a custom shader or `CompositorEffect`), `LightmapGI` with a baked lightmap, `VoxelGI`, SDFGI on the `WorldEnvironment`, multiview (XR), shadow depth precision (16/32-bit), and omni shadow mode — dual paraboloid and cubemap (default) are separate variants.

Changing any of these at runtime restarts compilation and stutters immediately. Confine changes to a settings screen behind a loading screen. Only one MSAA level is tracked at a time, so different levels on different viewports stutter unavoidably.

## Warm up dynamically instanced effects

Preloading a `PackedScene` is not enough — the pipelines need the scene *instanced in the tree at least once*, even hidden or off-camera. For effects spawned by gameplay (bullets, explosions, hit VFX), attach a hidden instance to something guaranteed to exist, e.g. the player. Enable **Editable Children** on that instance to disable its script and hide sub-nodes that would otherwise act.

## Shader baker (export)

Export preset → Shader Baker → Enabled. Bakes source into the **intermediate** format only, skipping the shader compilation step at runtime; it does **not** bake pipelines and does **not** fix existing stutter — it cuts first-launch load time, most on D3D12 and Metal. Costs a longer export and a few MB of PCK.

Bakes only for the driver in `rendering/rendering_device/driver` for that target, and only for drivers the editor's own host OS supports: Windows → Vulkan + D3D12, macOS → Vulkan + Metal, Linux/Android → Vulkan. No effect on Compatibility (so none on web), and unsupported when exporting with `--headless`.
