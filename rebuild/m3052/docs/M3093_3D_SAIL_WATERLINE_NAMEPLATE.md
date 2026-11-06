# M3093 – 3D Gameplay Ship: Waterline, Two-Sided Sails, Stable Captain Plate

This iteration follows the user's Android screenshots of the new 5,918-triangle PBR and Shaded GLBs. Both remain genuine, freely rotating 3D ships. Their source GLB binary files are untouched.

## Render improvements
- Two-sided materials applied to the player's instance of the uploaded gameplay PBR and Shaded versions. Backfaces on thin sail cloth remain textured when the ship rotates. Materials are duplicated and not written back into the source.
- PBR normal strength capped at 0.70 to reduce distracting microcontrast while preserving albedo and emission.
- Slightly softer sunlight and brighter fill/ambient for the transparent 3D fleet viewport. NPC appearance can also be affected by this shared lighting.
- In the existing 2D sea draw pass, subtle waterline foam runs alongside the submerged hull and moves with measured speed. No opaque circular hover platform. Existing wakes still depend on real movement.
- The player's 3D nameplate uses a yaw-independent hull footprint computed from the selected model length, width, immersion and camera zoom. HP, shield and deck UI retain their prior relative positions, and game stats/saves are unchanged.

## Test
- In the shipyard, equip the black-green test ship (skin 29). Select B (PBR) or C (Shaded) under M3092 and HYBRID or 3D on the map.
- Hold a consistent zoom, rotate through eight headings and confirm sail backs, stable player label, and visible but subtle water contact. Compare to the original A in the same camera.
- The automated Godot UI test checks both live GLB materials and fixed captain label position through headings.

No NPC AI, physics, gameplay assets, original GLB geometry, or saves changed.
