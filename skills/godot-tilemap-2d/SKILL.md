---
name: godot-tilemap-2d
description: "Write, edit, or debug Godot 2D tile maps: TileMapLayer, deprecated TileMap, set_cell, tile custom data, terrains, and tile collision."
---

# TileMap 2D

Target Godot 4.7+.

## TileMapLayer, never TileMap

- `TileMap` is deprecated since 4.3. Use one `TileMapLayer` per layer; layer index parameters no longer exist. Convert old scenes from the TileMap bottom panel → toolbox icon → *Extract TileMap layers as individual TileMapLayer nodes*.
- Every layer needs a `tile_set`; sibling layers normally share one `TileSet` resource.
- Cell coordinates serialize as 16-bit signed ints; X and Y outside `-32768..32767` wrap on save.

## Cells

```gdscript
@onready var ground: TileMapLayer = $Ground

ground.set_cell(Vector2i(3, 5), source_id, Vector2i(0, 0))  # coords first, no layer arg
ground.erase_cell(Vector2i(3, 5))
```

- `set_cell(coords, source_id = -1, atlas_coords = Vector2i(-1, -1), alternative_tile = 0)`. Any of `source_id = -1`, `atlas_coords = Vector2i(-1, -1)`, or `alternative_tile = -1` erases the cell and resets all three identifiers.
- `alternative_tile` defaults to `0` in `set_cell()` but to `-1` in `get_used_cells_by_id()`, where it means "any".
- With a `TileSetScenesCollectionSource`, `atlas_coords` must be `Vector2i(0, 0)` and `alternative_tile` is the scene id.
- Flip and rotation are bit flags packed into `alternative_tile`, not properties:
  ```gdscript
  const ROTATE_90 := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
  ground.set_cell(coords, source_id, atlas_coords, alt | ROTATE_90)
  ```
  Read back with `is_cell_flipped_h()`, `is_cell_flipped_v()`, `is_cell_transposed()` (atlas sources only).
- Use `get_neighbor_cell(coords, TileSet.CELL_NEIGHBOR_*)` instead of adding `Vector2i(1, 0)`; only it is correct for hex and isometric layouts.

## Coordinates

- `local_to_map()` and `map_to_local()` use the layer's **local** space: `local_to_map(to_local(body.global_position))`, or `local_to_map(get_local_mouse_position())`.
- `map_to_local()` returns the tile center, not its corner.

## Per-tile data

```gdscript
var data := ground.get_cell_tile_data(ground.local_to_map(ground.get_local_mouse_position()))
if data:
    var power: Variant = data.get_custom_data("power")
```

- `get_cell_tile_data()` returns `null` for empty cells and non-atlas sources — always null-check.
- `TileData` is read-only at runtime except inside `_tile_data_runtime_update()`.

## Terrains

`set_cells_terrain_connect(cells, terrain_set, terrain, ignore_empty_terrains = true)` joins matching neighbors and may rewrite adjacent tiles; `set_cells_terrain_path()` follows cell order for roads and rivers. Both are expensive — pass the whole array in one call, never cell by cell.

## Collision and navigation

- Shapes come from the `TileSet` physics layers; toggle with `collision_enabled`, inspect with `collision_visibility_mode`. Same pattern for `navigation_enabled` and `occlusion_enabled`.
- Set `use_kinematic_bodies = true` only for layers that move (moving platforms).
- `physics_quadrant_size` (default 16) merges similar tiles' shapes per quadrant, so a collider covers many cells. Recover the tile with `get_coords_for_body_rid(rid)`, passing `KinematicCollision2D.get_collider_rid()`.
- Call `set_navigation_map()` to keep a layer's navigation separate from other layers.

## Updates and ordering

- Cell edits are batched to the end of the frame, so scene tiles from a `TileSetScenesCollectionSource` initialize *after* their parent and derived state read right after `set_cell()` can be stale. `update_internals()` forces an update — expensive, never per cell in a loop.
- The `changed` signal fires very often during batch edits; defer real work with `call_deferred()`.
- For runtime visual overrides implement `_use_tile_data_runtime_update(coords) -> bool` and `_tile_data_runtime_update(coords, tile_data)`, then call `notify_runtime_tile_data_update()` when the predicate's result changes. Returning `true` broadly is a significant performance cost.
- Top-down depth: enable `y_sort_enabled` (from `CanvasItem`) and shift the layer with `y_sort_origin`. `x_draw_order_reversed` applies only while Y-sorting.
