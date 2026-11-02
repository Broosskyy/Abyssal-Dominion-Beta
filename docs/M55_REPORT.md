# M55 — Earned Main-Fleet Unlocks + Unified Ship Browser

- Main-fleet map-level thresholds now mean ELIGIBILITY only. Reaching a map level no longer auto-adds every eligible main design to ownership.
- Existing saves are migration-safe: already-owned main designs are preserved; M55 does not revoke them.
- Added explicit local PL6–15 boss reward hooks:
  - level 6 boss -> ship_main_01
  - level 8 boss -> ship_main_02
  - level 10 boss -> ship_main_03
  - level 12 boss -> ship_main_04
  - level 14 boss -> ship_main_05
- Boss reward is awarded on credited boss defeat, then the map-level progression advances and refreshes eligibility.
- Added MainShipRewardCatalog and `pl6_15_ship_rewards.json`; future cadence remains data-driven.
- PlayerShipRoster now separates `eligible_main_ship_ids` from `owned_ship_ids`.
- Legacy starter-array preview behavior was replaced by a unified preview ID list containing starters + owned designs + currently eligible main designs.
- Harbor equip remains owned-only.
- Ship Mastery/Shipyard terminology now distinguishes GESPERRT, ELIGIBLE/FREISCHALTBAR and IM BESITZ.
- No live/server reward authority is claimed.
