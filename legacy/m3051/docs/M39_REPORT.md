# M39 — Generic Event Framework + Mobile Combat UI Refinement

M39 follows the V3.0 master bible focus: generic event framework + Haunted Tide compatibility, while preserving the sea map as the primary play surface.

## Implemented
- EventRuntime + `data/event_framework.json` as local prototype contracts only.
- Haunted Tide compatibility sample with Event Currency, World Meter, Milestones, Event Shop entries, event cannon ammo, event harpoon, event healing ammo, event supply and event blessing hooks.
- Event HUD is intentionally minimal/non-modal: a compact status chip only. Details live in the Events hub.
- Event claims/purchases are explicitly preview-only. Live rewards remain server-authoritative/idempotent.
- Ammo/Items picker now uses two-column touch cards in wide landscape and a one-column fallback on narrow/portrait screens.
- Picker continues to own input while open so touches never leak into Tap-to-Sail.
- Existing high-DPI/safe-area responsive behavior remains intact.

## Not implemented
- No live event schedule, backend economy, server world meter, authoritative reward claims, guild event persistence or final Haunted Tide art/assets.
- No native Godot 4.7.2 device acceptance was possible in this environment.
