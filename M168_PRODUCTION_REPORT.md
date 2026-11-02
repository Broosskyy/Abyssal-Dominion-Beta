# M168 — Mobile HUD/Menu Runtime Audit, Catalog Decoupling & Crafting Stations

M168 continues the master concept with a production pass focused on interaction correctness, mobile usability and removal of legacy content hardcodes.

## Legacy/runtime fixes
- Arsenal no longer presents the obsolete deck cap 3; it reads the configured deck cap (currently 10).
- Cannon purchase cap and price in Arsenal now come from gameplay rules rather than fixed 6/150 UI values.
- Arsenal stock checks use each item’s data-driven stack limit.
- Ammo selection in Arsenal, combat picker and quickslots resolves IDs through CombatCatalog, so added ammo using existing behavior primitives does not require extending fixed UI allowlists.
- Game-state ammo restore clamps against the runtime ammo catalog, not the original built-in constant array.
- HUD ammo count uses the currently resolved ammo ID.

## Crafting station progression
- Powder Magazine, Rune Foundry, Hunter Lodge and Siege Workshop now have persistent levels 0–10.
- Upgrade costs are data-driven in `m168_runtime_mobile_menu_audit.json`.
- Modern crafting recipes enforce their declared station and optional station-level requirement.
- Station levels are included in save/export/import with validation.

## Mobile/interface
- M167 responsive profiles remain active and M168 formalizes additional combat HUD/menu audit requirements.
- Runtime ammo labels/counts avoid stale fixed lists.
- Menus retain vertical scrolling, safe-area handling and reachable close/back actions.

## No-code boundary
Existing behavior primitives can be recombined through content data for ammo/cannons, recipes, station costs/requirements, source bindings, labels/icons/VFX/tooltips and mobile profile values. New behavior primitives, authority boundaries, payment adapters, networking or rendering primitives still require reviewed code.
