# M58 — P0 Visual Integration Readiness

M58 converts the first user-production wave into concrete, replaceable Godot slots.

- 13 P0 GLB import profiles with meter/+Y/+Z/waterline contracts.
- Dedicated early NPC slot resolver for scout, raider, gunship/sniper and heavy/tank.
- Haven's Reach uses a dedicated harbor slot.
- Tropical small/medium and elongated/cliff-cove island slots are resolved while preserving old fallbacks.
- Early monster gets its own stable production slot.
- Every new specialized slot clones a working placeholder fallback in the placeholder manifest.
- Asset Preview is upgraded to an M58 QA/Replacement Lab with an `M58 GLB WAVE` filter and visual QA lines.
- No visual GLB owns collisions, input, stats or gameplay logic.
- No native Godot 4.7.2 runtime/device QA was available in this environment.
