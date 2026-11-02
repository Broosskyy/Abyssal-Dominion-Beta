# M79 — Marker Priority + Haven's Reach / Monster-Zone / Mobile Budget Pass

M79 focuses on visual hierarchy instead of adding gameplay authority.

- World and minimap semantic POIs now use a shared priority catalog. Objective/harbor/combat-relevant markers outrank wreck/salvage/navigation dressing.
- World POI markers avoid reserved HUD rectangles and existing ship nameplates; lower-priority markers are dropped rather than drawn on top of combat UI.
- Minimap POIs sort priority first, distance second.
- Haven's Reach now wires the prepared net-rack and lantern-post slots into its stable composition.
- Monster-warning/nest POIs receive visual-only bone/reef context through stable slots and procedural fallbacks.
- Added a concrete PL1–5 object/material budget. MultiMesh stays deferred until native profiling because current repeat counts are small and replacement flexibility matters.
- Added static save-migration fixture cases for fresh v2, v1 stage-1/stage-5, pre-version trial and ownership preservation.
- Added six more stable P0 visual slots.

No rewards, encounter stats, navigation authority or backend/server state are changed. Native Godot 4.7.2 parser/runtime, GPU profiling and Android device screenshots remain pending.
