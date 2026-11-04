# M36 — PL1-5 Harbor Economy Vertical Slice

## Implemented
- Local Gold-based harbor economy contract in `data/early_economy.json`.
- Docking no longer grants a free full hull repair or free repair consumables.
- Harbor repair now has a transparent quote based on missing hull and is purchased with earned Gold.
- Standard Iron ammo, Explosive ammo, Chain ammo, Harpoons, repair consumables and boosts are purchasable individually at the harbor.
- Dead-end protection remains deliberately narrow: if Iron ammo is exactly empty when docking, only 30 emergency Iron rounds are granted.
- Existing 120-Gold harbor bundle remains as optional convenience for the local vertical slice.
- Port checkpoint / respawn behavior is unchanged.
- No Bazaar, premium economy, Guild Treasury, online wallet or authoritative transaction system is simulated.

## Compatibility
This is an offline/local prototype economy. Live ownership, currency and transactions must move to server authority in a real MMO build.

## Validation
Static contract checks added in `tests/m36_runtime_test.gd`. Native Godot 4.7.2 / Android runtime still requires external execution.
