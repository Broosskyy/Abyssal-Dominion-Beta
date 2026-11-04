# M6 report — Persistence, progression, missions and shipyard

## Delivered

- Versioned local save envelope at `user://seefight_save_v1.json`
- SHA-256 payload guard and previous-save backup fallback
- Autosave after twelve seconds of dirty state plus save on sector change, docking, focus loss and close request
- Restoration of sector, position, hull, repair charges, cannon, ammunition, last port and checkpoint
- Persistent level, XP, coins and three upgrade tracks
- Hull upgrades: +12% maximum hull per level
- Cannon upgrades: +10% base cannon damage per level
- Sail upgrades: +4.5% cruise speed per level
- Ten levels per upgrade track with escalating coin cost
- Rotating Corsair Hunt, Sea Salvage and Harbor Route missions
- XP and mission credit for hostile sinks, loot collection and harbor visits
- Responsive harbor shipyard for keyboard, gamepad and touch
- Desktop: 1/2/3 purchase upgrades; G closes or reopens the nearby shipyard
- Mobile: contextual HULL/CANNON/SAILS/CLOSE action bar

## Save boundary

The same `user://` implementation is used on Android, iOS, Web and Desktop. Web persistence depends on browser storage and can be removed by clearing site data. M6 is local-first and does not claim account sync, cloud backup or server authority.

## Verification

- Complete GDScript parser/lint validation
- M5 platform contract remains green
- M6 gameplay contract verifies save guards, restore paths, module order, progression, missions, loot, docking and Mobile shop wiring
- No real visual/runtime claim is made until the project has been launched in Godot 4.7.2 and captured from the running game
