# M295 Production Report

Asset audit found that `npc_scout_01.glb` and the active `npc_raider_01.glb` were byte-identical. M295 creates a new replaceable Raider placeholder GLB using a reproducible, standard-library-only build script. The *whole existing ship mesh* receives a different footprint, adjusted normals and a dark raider palette. The resulting file has one GLB node, one mesh and six material surfaces: it is one complete model, not interchangeable hull, mast or sail parts.

The existing `npc_raider_01` slot now points to the M295 GLB in the runtime placeholder manifest, M289/M290 intake and readiness. The old P0 structural Raider decorator is skipped only when this complete GLB is in use; other legacy/fallback slots are unchanged. Collision, motion, combat, AI, rewards, economy and server authority are not altered. Existing unique starter-ship GLBs are preserved. The new model is not final art; replacement stays possible at the same stable slot.

Seafight and Battle of Sea remain clean-room genre/UX references only. Native Godot/desktop/Android rendering, GPU budget and visual quality remain NOT_EVALUATED.

Validation: 464/464 existing regression/integration checks and 17/17 discovered unit tests passed (481/481 total); 568/568 JSON files parsed; the M295 GLB binary structure, stable-slot wiring and SHA-256 were checked. This is static validation, not native gameplay or visual QA.
