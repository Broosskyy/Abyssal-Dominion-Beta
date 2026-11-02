# M172 Production Report

## Status
`M172_PROGRESSION_INTERACTION_BONUSMAP_CRAFTING_SHIPYARD_PASS`

Master concept: **V3.8**. Existing seekarte/gameplay camera and world presentation remain unchanged.

## Implemented
- Bonusmap harbor start presentation no longer duplicates Silver/Abyss/Legendary entry costs and item names; it reads the owning runtime/config. Gold eligibility now reads its runtime config while retaining its own entry contract.
- Added explicit crafting requirement state via `PlayerInventory.m165_recipe_status()`: port, station level, gold, missing materials, output cap and invalid recipe/output states are resolved before crafting.
- Progression hub displays the actual crafting failure/requirement reason instead of leaving failed craft actions unexplained.
- Craft execution reuses the same requirement resolver, reducing UI/runtime drift.
- Shipyard source list now deduplicates IDs across starter catalog and long-term progression designs without changing camera, preview resolver or asset pipeline.
- Added M172 runtime progression catalog/contracts and admin authoring types for bonusmap entry presentation, crafting requirements, shipyard catalog presentation and interaction feedback.
- Production/server authority boundaries remain unchanged.

## QA
Run `python tests/m172_progression_interaction_test.py`. JSON and ZIP integrity are validated during packaging. Full Godot/Android playtesting still requires an engine/device environment.
