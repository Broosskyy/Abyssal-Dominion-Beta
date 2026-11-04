# M68 — First Monster Pipeline + PL1–5 Encounter Visual Polish

## Master alignment
The first monster is a P0 asset. The master pipeline calls for consistent multi-view concepts, a Hero GLB with clean topology, creature-appropriate rigging, idle/move/attack/hit/phase/death-submerge animations, gameplay hit areas/harpoon impact points, LOD0/1/2 and mobile-reduced VFX. This milestone implements the technical replacement/QA side without inventing final art.

## Implemented
- `monster_early_01` is now explicitly active as the P0 Hero GLB/rig slot.
- Added rig, animation, coordinate, waterline, visual-anchor and LOD acceptance contracts.
- Added optional AnimationPlayer/AnimationTree discovery bridge. Animation remains presentation-only.
- Added visual anchors for head, harpoon-center, mouth VFX and body VFX. They are not gameplay hitboxes.
- Fixed monster spawning so a regional boss visual slot cannot accidentally replace the P0 `monster_early_01` slot.
- Added a `monsters` presentation group.
- Improved procedural monster fallback bounds/scale profile and mobile LOD policy.
- Prepared attack/hit/phase/death/submerge VFX slots.
- Added PL1–5 visual hierarchy QA so neutral/hostile/elite/admiral/monster presentation stays readable and consistent.
- No new combat balance values, rewards, weak-point mechanics or backend authority were invented.

## Performance
M68 uses per-quality visual LOD/VFX budgets. Godot supports automatic mesh LOD and visibility ranges together; the contract keeps gameplay independent from either.

## QA limitation
Static project checks only. Native Godot 4.7.2 parser/runtime/Android device QA is still required.
