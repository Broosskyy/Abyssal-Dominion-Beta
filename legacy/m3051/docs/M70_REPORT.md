# M70 — Mobile / Content / Graphics Optimization + PL1–5 Acceptance Preparation

## What changed
- Touch-density HUD action hitboxes now enforce a 56px logical comfort floor after responsive layout overrides.
- Added a deterministic, read-only PL1–5 native acceptance snapshot/harness. It observes progression, starter ownership, port state, target relation and mobile layout without granting rewards or changing combat.
- Added ten stable P0 world-content model slots for lighthouse, dock, warehouse, market stall, quest board, palm cluster, rock cluster, small wreck, navigation buoy and crate stack.
- Added eight polished, text-free, replaceable onboarding/content UI icons.
- Added mobile/content/graphics budgets aligned with the existing M63 water/VFX and M64 texture/material policies.
- Asset QA now has an M70 CONTENT filter.

## Important
This does not claim the native acceptance run passed. Godot 4.7.2 runtime/device QA is still required. Missing final GLBs keep using existing/procedural fallbacks; decorative models never own gameplay truth.
