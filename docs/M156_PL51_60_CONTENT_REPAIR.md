# M156 — PL51–60 Gameplay Expansion & Legacy Content Repair

M156 activates the previously staged 51–60 gameplay band as a local prototype while keeping live authority data-driven and replaceable.

## Playable progression

PL50 Pirate Trial now advances to PL51. Levels 51–55 form **Dreadwater March** and levels 56–60 form **Iron Maw Reach**. Every level has XP, Hunter, regional, W5 elite-chain and Dominion-shard requirements. PL55 and PL60 are explicit Pirate Trial gates. Completing PL60 unlocks the existing Endgame Prestige rotation.

## World expansion

Ten new stable sectors (`SECTOR-052` through `SECTOR-061`) extend the existing registry without replacing prior sector IDs. Their NPC pools reference the already-produced W5 replaceable visual slots `SHIP-PROG-051` through `SHIP-PROG-060`. This is visual/runtime encounter usage only and does not grant player ship ownership.

## Prior-content repairs

M156 also fixes stale hard caps and an older UI/runtime gap: the world/region/admin validation layer now accepts PL60, dynamic quests default to 60, POI population continues through 60, the objective HUD continues past PL25, and runtime Pirate Trials can finally be handed in from the Harbor Trials panel. Capstone Hunter selection now uses the resolved spawn-table slot count rather than the original biome slot count, which matters when regional or admin content extends a spawn pool.

## Authority and tuning

All new numbers are local prototype defaults. They remain eligible for LiveConfig/Admin overrides and do not claim recovered server balance. Ship eligibility and ship ownership remain distinct, and the W5 GLBs remain clean-room replaceable placeholders.
