# M10 — Sector encounters, admirals and real engine validation

## Implemented

- Each of the twelve existing sectors now rebuilds its own population instead of repositioning four shared NPCs.
- Tropical, desert and snow spawn tables select different combinations of raider, scout, tank and sniper. The existing recovered Clipper, Barco and Chalupa meshes are reused; no new original ship meshes were extracted in M10.
- Four regular NPC slots plus at most one admiral keep the population bounded on mobile and Web.
- Destroyed NPCs are replaced after 10/12/14 seconds according to biome. The director owns this lifecycle; NPC health no longer independently respawns the same ship.
- Kill counters trigger a biome-specific admiral at 4/5/6 credited regular kills. A defeated admiral resets the count and starts a 45-second cooldown.
- Hull, damage, XP and coin rewards scale with the existing map level. XP is credited on a player kill; coins remain a collectible drop. Admirals also drop repair salvage.
- HUD displays the admiral counter/cooldown and arrival/defeat notices. Admirals have larger gold minimap dots.
- Kill counts and cooldowns are saved per sector with the existing local save. Old M9 saves default to zero counters.
- Sector changes clear old targets, navigation, port state, enemies, loot and projectiles. Pending deferred loot cannot attach to a replacement sector.
- Spawn sampling excludes player proximity, island collision proxies, harbor zones and nearby ships. If no safe point is available, the slot retries later.

## Source evidence versus reconstruction

The user-provided IL2CPP metadata in `docs/il2cpp/relevant_game_types.csv` contains:

| Original contract | M10 mapping |
| --- | --- |
| `WorldMapNpcSpawner.SpawnMapNpcs`, `SpawnNpc`, `OnNpcDied`, `RePopulateNpcAsync` | `EncounterDirector.configure`, `_spawn`, `_on_npc_sunk`, pending slot timers |
| `WorldAdmiralHandler.AddNpcKillCount`, `ResetAdmiralCount` | per-sector kill counters and reset on admiral defeat |
| `AdmiralSpawnConfig.RequiredNpcs`, `AdmiralNpcId` | local biome threshold and admiral profile |
| `RewardsNpc.Gold`, `Experience` | local coin drops and XP table |
| `PlayfabGameData.MapsConfig`, `IdToNpc`, `AdmiralSpawnConfig` | offline `data/encounters.json` |

These signatures establish system structure, not original function bodies or production values. All M10 NPC titles, stats, thresholds, delays, rewards and map-level scaling are explicitly **local test balancing**, not original recovered server configuration. No original servers or PlayFab endpoints are contacted.

## Runtime blockers discovered and repaired

The first actual engine run exposed failures that prior substring-based contract checks missed:

- Added explicit GDScript types where Variant inference prevented compilation (movement, input, progression, HUD, wakes and AI).
- Converted the existing SVG start artwork to a real PNG for Godot's boot splash.
- Deferred navigation-marker and recovered harbor creation until the parent scene is ready.
- Repaired dangling normal indices in three runtime coastline OBJ files and one duplicate reference OBJ. Vertex positions, UVs and triangle order are unchanged. Godot now generates missing normals. The included repair script is repeatable and the old M9 archive retains the unmodified extracts.
- Added single-consumption guards for projectiles/loot and made sinking stop physics immediately.

## Verification

- Real headless engine import and behavior test completed with Godot **4.5.1.stable.official.f62fdbde1**, used as a compatibility test runtime.
- **86/86 behavior assertions** passed, including M9 purchases/equipping, no double reward on repeated lethal damage, delayed replacements, one admiral, cooldown/reset, state roundtrip, twelve-sector population/clearance, coast loading, and recovered harbor attachment.
- The final import and behavior logs contain no engine errors. `tools/run_engine_checks.py` rejects logged errors even if the engine exits with code zero.
- `tools/validate_m10_encounters.py` separately checks data and source wiring; these are not runtime tests.
- Project configuration continues to target Godot **4.7.2**, Compatibility rendering, Web, Android, iOS, Windows, macOS and Linux.

**Still unverified:** Godot 4.7.2 specifically, a rendered frame/shaders, exact visual scale/waterline, touch-device behavior, export installation and platform performance. No runtime screenshot is claimed.

## Test commands

```sh
python3 tools/run_engine_checks.py --engine /absolute/path/to/godot
python3 tools/validate_m10_encounters.py
python3 tools/validate_platform_contract.py
```

The engine test marks its scene as test-only and does not read or write the user's gameplay save.

## Deliberate limitations

- Admiral health and spawn positions are not persisted. Leaving and re-entering a sector with a triggered admiral recreates it at full health; its kill threshold stays reached until defeat.
- Inactive-sector and offline cooldowns do not elapse. This is a local simulation, not server-time synchronization.
- Clear spawn locations use collision proxies, not pixel-perfect coastline geometry. Continuous obstacle-avoiding ship navigation remains pending.
- No guild conquest, tower combat, original multiplayer, original skins or exhaustive original NPC catalog is included.
- Recovered assets remain private-test references and require replacement/licensing before distribution.
