# Abyssal Dominion M3052 — rebuilt sea chart

Open **this directory's** `project.godot` with Godot 4.7.2. This is an independent Node2D scene and fixed-step simulation; it does not inherit the old M303/M3051 scene stack.

This reconstructs the unfinished M3052 work described in the previous chat. That original working directory was not recovered. The verified M3051 snapshot remains available at the repository root.

## Implemented

- New 4400 × 3200 sea chart, nine navigable island landmarks, animated blue ocean and minimap.
- Twenty-six test ship designs (ten supplied illustrations plus sixteen directional reference hulls) selectable through the scrollable shipyard without resetting player state.
- Sixteen directional NPC ship atlases: four retained reference ships and twelve newly extracted SeaBattles hulls. Full sails always use the visually audited second row; moving never selects a damaged-looking row.
- Sixteen independently moving NPC ships plus animated Tiamat. Patrol, chase, return, fire, sinking and respawn are simulation states.
- Click/tap routes around islands, direct movement, facing-independent fire, camera drag, pinch/wheel zoom, minimap navigation and recenter.
- Visible cannon/chain/harpoon projectiles, damage on impact, incoming NPC shots, chain slowdown, range/line-of-fire/ammo rules, repair restrictions and physical single-payout loot.
- A kill quest, ammo purchases, local guest wallet/ammo/design/quest persistence.
- Desktop and narrow landscape HUD; scrolling shipyard, real controls and isolated automated QA.

## Controls

Tap water to sail. Tap an enemy and press **FEUER**. Full cannonballs or chain shot target ships; harpoons target the monster. Sail over loot to collect it. Repair requires six seconds without a hit. Pinch/wheel zooms; drag/right-drag pans; **ZIEL** recenters. The shipyard contains all 26 test cosmetics and ammunition restocking.

## Validation and Android

`tests/simulation_test.gd` exercises actual navigation, NPC movement, projectile timing, rewards and combat invariants. `tests/ui_test.gd` loads the scene and checks controls at 1280×720, 844×390 and 720×405, scrollability, equipment and persistence. Each CI test gets fresh user storage.

The dedicated `m3052.yml` workflow exports and verifies `releases/M3052/ABYSSAL_DOMINION_M3052_REBUILD_ARM64.apk`. The separate development package `com.abyssaldominion.rebuild` installs beside M3051. Its debug key is kept in the private Actions cache, not source control. Production signing and an updater are not implemented.

## Remaining scope

This rebuilt scene is **local guest gameplay**. M3051's separate server test remains in the old project; the new simulation has not yet been networked. Accounts, persistent server progress, public WSS operation, cross-device acceptance, PvP, guilds and the full reference-game feature set remain open. Android export/signature checks are not a physical-device playtest. The visual target is not yet a pixel-identical recreation of the screenshots.

All selected PNGs have hashes and provenance under `assets/`. Supplied/reference artwork is retained for private development; public redistribution rights have not been established. Original multi-gigabyte source archives are not duplicated in Git.
