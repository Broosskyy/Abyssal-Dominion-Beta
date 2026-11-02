# M78 — Haven's Reach / Wreck / Monster-Area Content + Save Migration Audit

M78 makes the PL1–5 world visibly denser while keeping every new content element replaceable and non-authoritative.

- Haven's Reach now uses stable `harbor_id` metadata instead of fragile display-name matching.
- The harbor composition now includes crane, rope bundles, fish crates, wayfinder and salvage-hook dressing through stable model slots with procedural fallbacks.
- PL3–5 semantic POI variety now includes a wreck beacon and monster-warning marker. These remain visual-only and do not imply rewards, danger calculations or quest completion.
- Salvage dressing can use floating debris, wreck planks, barrels and salvage hooks with a strict rarity-based cap.
- GameState migration order was audited and made explicit: roster loads before voyage because voyage may grandfather v1 starter entitlements.
- Saves now carry `m77_beginner_progression_schema` without invalidating the existing global save envelope version. Older compatible saves are marked dirty after reconciliation so the new schema persists on the next safe save.
- Added six more stable P0 content slots and a world-density contract.

No backend/server authority or new reward logic was introduced. Native Godot 4.7.2 parser/runtime and Android device QA remain pending.
