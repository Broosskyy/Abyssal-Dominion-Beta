# M228 — Living Sea Encounter Distribution

M228 moves back from harbor-specific work into the playable sea chart. Existing encounter slots now receive a stable regional living-sea profile: patrol ships circle locally around their authored M197 regional spawn anchors, monsters retain their own territories, and admirals retain their deliberate staging areas. This adds visible motion and regional identity without raising the enemy cap or filling every stretch of water.

The patrol motion is deliberately local. It uses the already spawned ship's anchor and metadata only; it is not a second navigation/pathfinding system. Once combat starts, the existing EnemyShipAI tactical states, leash logic, M217 respawn disengage safety and M218 broadside behavior remain authoritative. Beginner seas keep their existing neutral-until-attacked rule; later encounters remain hostile under the existing rules.

M228 also exposes stable region temperament, relation-read and world-priority metadata for later nameplate/event/asset presentation. Existing DynamicSpawnTable, RegionalEncounterZoneCatalog and event runtime remain the content authorities. Combat stats, rewards, loot, collision, camera and cross-platform world parity are unchanged.
