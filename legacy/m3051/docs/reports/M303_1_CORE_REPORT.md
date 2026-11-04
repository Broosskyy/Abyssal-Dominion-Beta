# M303.1 — SeaBattles-style playable core (LOCAL prototype)
Date: 2026-10-28
Branch: `rebuild/classic-seafight-m303`
Base: protected archival M302 on `main`, no changes merged to main.

## What was actually committed
- `scripts/classic/classic_sea_map.gd` — independent local sea chart boot path: water plane, orthographic oblique camera, existing asset placeholders, NPCs, monster, targeting, local cannon/harpoon effects as simulated HP values, loot, repair, gold, local sinking/respawn and responsive overlay.
- `scripts/classic/classic_route_planner.gd` — small visibility graph using expanded island shoreline radii for multi-waypoint detours. Does not try to cross islands when targeting an otherwise reachable water location.
- `scripts/classic/classic_ship_visual.gd` and `assets/classic/sprites/*16dir.svg` — 16-frame directional ship texture *technology demo* using independent placeholder art, replaceable with original/licensed assets; GLB fallback if atlas cannot load.
- `project.godot` — entry on `scenes/classic/classic_sea_map.tscn`; Android touch emulates water-click.
- `tests/m303_classic_core_smoke.gd` — five pure route cases for Godot headless running: direct, avoid shore, reject target on island, reject out-of-bounds, multiple islands.
- The `README.md` and research files explain M302 archive vs active rebuild.

## Intended local gameplay loop for QA
1. Start at ship on map 10/2.
2. Tap water beyond an island; waypoint route must go around it.
3. Tap a hostile ship to select; press KANONEN FEUER; ship should take **simulated** damage without needing to align the player's bow to target.
4. Sail near floating gold to collect it. Verify counter is updated exactly once.
5. Switch weapon to HARPUNE; select Seemonster and attack.
6. Approach enemy ship and observe their periodic local counterfire. Press REPARIEREN; verify cooldown; if sunk, player respawns locally.
7. Use zoom/recenter/camera controls. Test screen taps on HUD do not steer.

## Verification performed in current chat
- Connected GitHub branch file reads verified: entry scene, route planner wiring, mobile pointer emulation flag, combat/monster, loot, repair, respawn, and test script exist.
- 11 of 11 **source presence / wiring** checks passed in the connected repo. These check existence of functions and relevant wiring, **not** GDScript compiler/runtime correctness.
- The route cases were written but **not executed**. Godot headless, Android/Web builds, on-device UI checks, live multiplayer and performance QA are **NOT_EVALUATED**. No APK/Web build was produced.

## Risks / next required fixes
- Verify GDScript imports compile; SVG atlas visual direction/orientation and projection need real Godot screenshot/QC.
- Waypoints are 2D visibility-graph prototypes around circular islands, not final navmesh. Stress-test narrow channels and map-edge obstacles.
- Existing GLBs and individual 16-direction sprites are NOT approved final ship art.
- Cannon/harpoon are local intent/damage simulations; no actual projectiles, server-authoritative hits, network snapshots or anti-cheat yet.
- Gold, damage, loot and repair are ephemeral. They never grant real account currency or persisted items.
- Expand enemy motion/AI, projectiles and full ship animations after visual camera/sizing regression test.

## Roadmap (no UI-only detours)
- M303.2: player ship turn smoothing, waterline/wake, projectile and hit presentation, camera/HUD safe areas; screenshot comparison against user-supplied SeaBattles references.
- M303.3: server-backed combat/movement proof; first online two-client sync and evidence.
- M304: combat/quest/ship progression with persisted inventories and complete loop.
- M305: distinct **ship castles**, **talent trees**, presets, decks, elite ships.
- M306+: real guild islands, events, social and economy, browser + Android release pipeline.

## Reproduce native-only test (not executed here)
```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/m303_classic_core_smoke.gd
godot --path . res://scenes/classic/classic_sea_map.tscn
```
