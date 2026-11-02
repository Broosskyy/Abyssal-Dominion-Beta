# M4 report — Asset Integration Wave 2 + Harbor Interaction

## Delivered

- Two additional source-traceable ship meshes: `Barco_low` and `NPCChalupa_victor`
- One complete tropical island family: `island_04`, `island_04_coast`, `island_04_bottom`
- Wooden pier mesh and related ship/island/pier textures
- Three dynamic ship visual profiles: Clipper, Barco and Chalupa
- Debug-only island and harbor adapters with procedural release fallbacks
- Independent island Main/Coast/Bottom material assignment
- Godot-native animated shoreline foam; no baked water or foam in the reference GLBs/OBJs
- Harbor proximity detection and responsive interaction hint
- Dock action: restore hull, refill three repair charges, stop vessel and set checkpoint
- Desktop `F` interaction and contextual Mobile `DOCK` action

## Asset boundary

All twelve Wave-2 records are marked `TEMP_REFERENCE` in `assets/reference_only/m4_wave2/manifest.json`. Every export preset excludes the complete reference-only tree. Production builds therefore use procedural fallbacks until owned, licensed or newly authored replacements are installed under `assets/production/`.

## Visual architecture

- Ship gameplay root, collision, targeting, weapon sockets and wake remain independent of the loaded visual profile.
- Island collision stays Godot-owned while visual Main/Coast/Bottom parts can be exchanged.
- Pier collision stays procedural and stable while the reference mesh is visual-only.
- Water, shoreline foam, wake, muzzle flash, projectile trail and impact effects remain Godot-native runtime effects.

## Verification

- `gdtoolkit` parses and lints the complete script tree without errors.
- Wave-1 and Wave-2 manifests resolve to existing files.
- All six release export presets exclude `assets/reference_only/**`.
- `docs/m4_asset_preview.png` is rendered from the extracted OBJ vertices and textures, not generated concept art.
- Runtime/export validation still requires Godot 4.7.2 and the platform export templates.
