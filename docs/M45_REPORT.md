# M45 — Replaceable Status/VFX Layer + Production Slot Foundation

M45 was re-scoped against the V3.0 Complete Master Bible, the V3.1 Ammunition/Special Items addendum and Asset Production Masterlist V2.

## Implemented
- Data-driven status visual catalog for burn, venom, armor break, spectral mark, repair block, barrier, veil, powder and plates.
- Stable UI slots + original placeholder SVG icons for every currently displayed combat status.
- World/nameplate status icons with remaining duration; capped to four to protect mobile readability.
- VisualAssetCatalog now supports prepared VFX and audio override groups in addition to models/UI.
- CombatVfx can load a final PackedScene replacement per VFX slot and falls back to procedural VFX when absent.
- New asset_replacement_matrix.json captures current families, priorities, fallbacks and required QA pipeline.
- New production_future_slots.json reserves stable IDs for 50 main progression ships, ~20 island bases, monster/projectile families and icon/VFX families without pretending final assets exist.
- Missing final assets remain non-fatal and gameplay values stay independent from visuals.

## Important
This milestone does not claim that the 707 Production Masterlist positions are produced. It builds the replacement architecture so future production can map into stable slots without system rewrites.

## Validation
Static JSON/source contract validation only. Native Godot 4.7.2 Android/iOS/Desktop QA is still required.
