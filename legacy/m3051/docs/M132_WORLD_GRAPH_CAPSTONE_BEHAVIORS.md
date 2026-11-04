# M132 — Stable World Graph + Qualified Capstones + Full Action-Item Component Pass

## World
The 51 currently authored core-sea sectors now have persistent `SECTOR-###` IDs in `world_sector_registry.json`.
Legacy Vector2i coordinates remain migration/layout metadata, not the navigation truth.
Boundary transitions resolve explicit graph neighbors. Save payloads write `sector_id` and retain legacy coordinates for old saves.
Encounter-state restore and Global Sea Map iterate real registry sectors instead of scanning every rectangular GRID_SIZE cell.
The Admin schema now includes sector/region creation and graph connection editing.

Known canonical V3.7 harbor corrections applied in registry:
- Sovereign Waters -> Sovereign's Rest
- Abyssal Dominion -> Dominion Gate
Legacy local harbor names remain recorded as aliases.

## High-level encounter semantics
PL40, PL45 and PL50 no longer use one monster as both Admiral and Hunter objective.
Each capstone has a distinct Admiral stable slot and a distinct Hunter/Monster stable slot:
- PL40 Void Admiral + Void Leviathan
- PL45 Sovereign Admiral + Sovereign Leviathan
- PL50 Legendary Dominion Admiral + Dominion Crown Guardian
Trial stages now record these separately.

## Admin-created action items
The Behavior Component whitelist/runtime now includes damage, status, heal, movement modifier, barrier, AoE damage,
target denial, repair block and recall. Existing classic action items are translated through the same executor.
Admins can therefore author new combinations of supported mechanics without adding a new GDScript branch.

No arbitrary executable scripts are accepted from Admin. Server publication/authority remains future backend work.
