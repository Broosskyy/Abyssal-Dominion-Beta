# M170 Production Report

## Status
`M170_MOBILE_RUNTIME_INTERACTION_AND_CATALOG_HARDENING_PASS`

Master concept: **V3.8**. M170 keeps the existing seekarte/gameplay camera and world presentation unchanged and continues hardening the actual M169 runtime/UI rather than replacing it with a new visual concept.

## Implemented
- Removed remaining active fixed-ammo dependencies from combat picker, combat detail, combat icon routing and local admin test-kit paths; these surfaces now resolve ammunition through `CombatCatalog`.
- Added depth-first `ui_cancel` handling to the HUD: detail card closes before picker, map and command menu.
- Fixed the older harpoon selection path so M165 merged runtime harpoon profiles (including later extension profiles) can be selected when owned, rather than validating only against the M163 list.
- Progression hub now renders the merged runtime harpoon list and closes with the standard back/cancel action.
- Captain Journal touch targets are raised/scaled for mobile.
- Meta Systems panel now uses safe-area-aware sizing, vertical scrolling, scaled touch targets and back/cancel close behavior.
- Added M170 data/catalog contracts for overlay priority, runtime catalog bindings, mobile screen audits and interaction guards.
- Added matching no-code/admin registry types while preserving server-authoritative boundaries for sensitive commerce, guild, account and staff actions.

## QA
Run `python tests/m170_mobile_runtime_interaction_test.py`. JSON parse/integrity gates are also run during packaging. Full Godot runtime/device playtest still requires a Godot environment/device.
