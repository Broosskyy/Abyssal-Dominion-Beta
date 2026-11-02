# M69 — PL1–5 Vertical Slice Closure Audit + NPC Visual Differentiation
1. Restrict P0 NPC fallback mapping to PL1–5 unless an explicit production slot is authored.
2. Give Friendly Coastal Sloop, Scout I, Raider I, Gunship I and Heavy I distinct polished fallback silhouettes/material profiles.
3. Unify target-frame relation truth with `EncounterRelation.status()` so target and world nameplate cannot disagree.
4. Audit starter unlock/economy/quests/harbor/monster/Pirate Trial PL5 against the current master vertical-slice contract.
5. Fix safe technical debt found during audit (progression signal/double emit/buy-or-equip assumptions where confirmed).
6. Continue mobile readability and performance polish; no fake multiplayer/backend state.
