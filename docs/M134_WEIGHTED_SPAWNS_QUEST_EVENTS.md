# M134 — Weighted Spawn Designer + Precise Quest Events + Live Event Multipliers

Admin Spawn Tables now control weighted NPC/Admiral entries, elite flags/tags, active slot count,
respawn cadence, Admiral kill threshold/cooldown, optional formations and sector/region/event targeting.

Encounter actors carry content IDs/tags. Dynamic quests can therefore target exact IDs or tags instead of only generic sink counts.
Loot pickups emit typed quest activity. POIs carry stable local IDs/tags and expose a generic quest interaction helper.

Active Event XP/Gold multipliers are now consumed by common mission rewards and Gold loot pickups.

The disabled Stormtide example composes Event -> Spawn Table -> Formation -> tagged fleet -> Quest with no code edit.

Production caveat: event scheduling still uses local client wall-clock in this prototype. Live production must use trusted server time.
