# M171 Production Report

## Status
`M171_RUNTIME_PRESENTATION_STATUS_AND_ARSENAL_INTERACTION_PASS`

Master concept: **V3.8**. M171 keeps the existing seekarte/gameplay camera and world presentation unchanged. The pass focuses on real runtime/UI hardening instead of a visual reinterpretation.

## Implemented
- Combat item selector is now driven by `ActionItemCatalog.item_ids()` plus supply/mode entries instead of a fixed action-item list.
- Action-item activation uses the generic runtime catalog path; supported new action items no longer require adding another UI match branch.
- Harpoon payload and support-ammo selection resolves the runtime payload catalogs before generic item handling.
- Combat picker labels/descriptions are generated from runtime ammo, payload/support and action-item definitions rather than the old fixed label dictionaries.
- HUD status chips now show every active `ShipHealth.ammo_effect_until` status, covering the newer generalized effect runtime rather than only four legacy IDs.
- Arsenal rows use runtime ammo/action-item names and `effective_offers()` instead of the static offer table for displayed purchasable rows.
- M171 data/catalog contracts document runtime presentation bindings, mobile interaction audits and authoring guards.
- Added matching no-code/admin content types while preserving server authority for sensitive commerce and entitlement mutations.

## QA
Run `python tests/m171_runtime_presentation_interaction_test.py`. Packaging also validates JSON and ZIP integrity. Full Godot/Android runtime playtesting still requires an engine/device environment.
