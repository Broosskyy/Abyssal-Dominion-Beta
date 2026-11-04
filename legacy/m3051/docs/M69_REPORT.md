# M69 — PL1–5 Vertical Slice Closure Audit + NPC/Relation Cleanup

M69 is a consolidation milestone rather than another isolated feature layer.

## Master alignment
The current master requires the PL1–5 vertical slice to contain Haven's Reach, selected Shattered Shores maps, all three starter ships, low-level NPCs neutral until attacked, at least one monster, elite/admiral encounters, quests, harbor/arsenal/repair, hull/shield/basic loot, Pirate Trial PL5 and a phone-readable HUD. M69 audits the existing project against that contract without pretending native acceptance has happened.

## Corrections
- P0 NPC archetype fallback mapping is now limited to combat level <=5 unless content explicitly supplies a production slot. Higher-level NPCs no longer silently inherit early-game P0 visuals.
- Target-frame neutral/hostile state now derives from `EncounterRelation.status()`, the same truth used by world nameplates.
- Friendly Coastal Sloop, Scout I, Raider I, Gunship I and Heavy I receive distinct interim silhouette decorators on fallback art only. User/final GLBs are untouched.
- Boss progression rewards now return the actual awarded design instead of storing/reading stale ship metadata.
- Added `progression_ship_awarded`.
- Removed the duplicate roster-change emission on a successful boss design award.
- Older local saves with already-owned reward designs get clearly marked `legacy_owned_migration` history rows. This is local migration provenance, not server audit reconstruction.

## Closure state
The source-side contract is substantially prepared, but PL1–5 is intentionally NOT labeled fully closed yet. Native Godot 4.7.2 parser/runtime testing and an actual phone playthrough through Pirate Trial PL5 remain required.

No multiplayer/backend/account state was fabricated.
