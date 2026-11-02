# M3 report — Asset Integration Wave 1 + Combat Depth

## Delivered

- A source-traceable `TEMP_REFERENCE` asset wave from the supplied Unity build
- Clipper hull, sails and port/starboard cannon meshes converted to OBJ
- Hull, sail, water foam, water bump, NPC bar and minimap textures converted to PNG
- Dynamic debug-only Godot visual adapter with procedural fallback
- Explicit export exclusion for the complete reference-only tree
- Target cycling and target HUD
- Light, naval and heavy cannon profiles
- Iron, explosive and chain ammunition profiles
- Armor, penetration, 8% critical-hit chance and chain-shot speed debuff
- Three repair charges and a timed speed-boost ability
- Raider, tank, sniper and scout NPC archetypes
- Coin and repair reward drops
- Desktop and mobile action controls

## Asset timing

Assets start in M3, not at the end. Wave 1 validates extraction, scale, orientation, material assignment and the replaceable `VisualRoot` integration path. Further waves should add island families, harbor modules, additional ship classes, VFX flipbooks and audio. Final production builds require owned, licensed or newly authored equivalents under `assets/production/`.

## Reference files

The authoritative record is `assets/reference_only/m3_wave1/manifest.json`. Each record includes its original Unity asset file and Path ID. `docs/m3_asset_preview.png` is rendered from the extracted OBJ vertices and exported textures; it is not a concept-art mockup.

## Verification

- All GDScript files pass `gdtoolkit` parsing and linting.
- All six export presets exclude `assets/reference_only/**`.
- Godot runtime/export testing remains required on a machine with Godot 4.7.2 and the relevant platform templates installed.
