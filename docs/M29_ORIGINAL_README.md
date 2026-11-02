# SeeFight 3D Reconstruction Lab — M29 / Godot 4.7.2

Revision 0.26.0. Use **Godot 4.7.2 stable** with matching templates.
Migration evidence and limitations: `docs/GODOT_4_7_2_MIGRATION.md`.

New: Splash → local Login/Register → captain home → **ZUR SEE** → return home.
Registration creates a passwordless local profile, **not an online account**.
Separate profile saves, transient guest mode and optional M12 save copy are included.
M23 deepens direct visual-master convergence with the larger combat cluster, enlarged helm/minimap, social/world utility controls, expanded log panel and closer top-navigation composition. M21 began direct convergence toward the user-owned 152969 visual master with expanded navy/gold navigation, stronger HUD hierarchy, brighter ocean response and rockier island silhouettes. M20 keeps the M19 world composition and adds a ship-readability, speed/turn-responsive wake, combat-VFX and Mobile comfort pass. M19 added varied island footprints, sizes, rotations and foliage density plus calmer layered ocean shading. M18 added a native navy/gold captain's journal with active/upcoming mission cards,
actual completion receipts and a harbor/service page. Tap the mission card or
WERFT to open it. Existing docking, supply and reward logic remains authoritative.
Physics-first picking reduces selection of ships behind physical obstacles.
M17 combat/loot and recovered ships/islands remain included. See `docs/M20_REPORT.md`, `docs/M19_REPORT.md` and `docs/M18_REPORT.md`.

Current M21 visual acceptance requires a fresh Godot 4.7.2 build/run; historical browser output must not be treated as the new render.
Headless menu-layout checks are not screenshots or a visual acceptance.
Do not present historical M12 screenshots as current M18 images.

**Quick preview:** from this folder, run `npm start` (or `python3 tools/preview.py`).
The bundled current Web build runs without a local Godot install. Read
`START_HERE_CURSOR.md` for Windows, phone/LAN access and rebuild setup.
Historical M12 WebGL screenshots only: `docs/qa_m12/`.

Separate offline reconstruction test based on technical observations and extracted assets from the supplied Unity 2021.3.45f1/IL2CPP build. This is not the Abyssal Dominion repository. Gameplay logic is reimplemented; original assets are private-test references, so this is not an entirely clean-room asset production.

## Engine

- Configured baseline: Godot 4.7.2 stable, Compatibility renderer
- GL Compatibility renderer
- GDScript
- Landscape-first, mobile/web compatible
- Runtime quality profiles for native Mobile, Mobile Web, Desktop Web and native Desktop

## Current playable systems

- Real 3D presentation with 2D/2.5D gameplay on the X/Z water plane
- Controlled oblique top-down camera; no free orbit or vertical gameplay
- Animated Compatibility-renderer ocean shader
- Modular player ship and four NPC ships with Visual, socket and anchor contracts
- Debug visual profiles for Clipper, Barco and Chalupa with safe procedural fallback
- Tropical, desert and snow island families with Coast/Ground/Underside separation
- Extracted Island 04 reference profile with independent Main/Coast/Bottom geometry
- Godot-native animated shoreline foam around every procedural island
- Desktop: WASD, Space to fire, T target, C/X cannon/ammo, Q repair, E boost, R respawn
- Mobile: visible bottom-left helm, explicit circular combat buttons and tap-to-sail on free water
- Mobile: conflict-free two-finger pinch zoom and safe-area-aware touch targets
- Desktop: optional gamepad steering, targeting, combat, repair, boost, map and docking
- Mobile: circular minimap opens global map; desktop: M toggles global map
- Selectable broadside targets, cannon projectiles, muzzle flashes, trails and impact VFX
- Tap/click near an enemy hull selects it; selected shots aim at its current position
- Optional AUTO salvos with range/reload/ammunition checks, no automatic pursuit
- Native gold chest and green repair-crate visuals, loot minimap dots and actual reward notices
- Three cannon classes and three ammunition classes with reload, velocity and damage profiles
- Armor, armor piercing, critical hits and temporary chain-shot slowdown
- Repair charges, timed speed ability, cooldown and coin inventory
- Speed/turn-responsive twin wakes plus stern foam driven by actual ship motion
- Damage, health, sinking and respawn
- Raider, tank, sniper and scout NPC archetypes with distinct combat tuning
- Reward drops with coin and repair pickup variants
- Persistent XP, levels, coins, loadout and local save/backup
- Persistent ammunition/consumable inventory, per-hull decks and owned cannon capacity
- Native scrollable arsenal: I / controller left-stick click / on-screen ARSENAL button
- Actual per-projectile ammunition consumption and harbor supply purchases
- Hull, cannon and sail upgrades plus rotating missions
- Native scrollable captain's journal: mission card opens tasks; WERFT opens harbor overview
- Real mission completion receipts, current/next tasks, no extra claim or duplicate payout
- Interactive harbor shipyard for keyboard, gamepad and Mobile touch
- Persistent three-vessel harbor catalog using the recovered Clipper, Barco and Chalupa families
- Ship browsing, coin purchase and equipping with distinct hull, armor, speed, turn and damage profiles
- Sector-specific NPC populations, bounded respawn slots, admiral kill counters and map-scaled rewards
- Persistent per-sector admiral progress and cooldowns, with arrival notices and gold minimap markers
- Model-bound-aware names and health bars, preferring below the player and above enemies
- Player/enemy selection rings
- Safe-area-aware responsive HUD
- Automatic pause/resume on Mobile and Web focus changes
- Adaptive 3D resolution and water/shore geometry based on platform and sustained FPS
- Twelve connected sea sectors in a 4×3 global map
- Boundary transitions with world-edge protection and transition banners
- Deterministic per-sector tropical/desert/snow island composition
- Ports, harbor lights, safe zones and checkpoint spawn positions
- Interactive docking: full repair, repair-stock refill and port checkpoint assignment
- Combat protection inside safe zones
- Coordinates, local minimap and global sea map

## Start

1. Open this folder in Godot 4.7.2 stable with matching export templates.
2. Confirm the Compatibility renderer.
3. Press the project Run button (entry flow). `scenes/main.tscn` bypasses the menus.

## Export targets

`export_presets.cfg` contains Web, Android, iOS, Windows, macOS and Linux presets. Install the matching Godot export templates first. iOS export and signing require macOS/Xcode.

See `docs/PLATFORM_MATRIX.md` for per-platform controls, quality profiles and external signing requirements. Run `python tools/validate_platform_contract.py` for the static M5 platform audit.

Run `python tools/validate_m6_gameplay_contract.py` for the persistence, progression, mission and shipyard audit. Save data uses Godot's platform-neutral `user://` location.

## Original content boundary

No original credentials, cloud endpoints or source code are bundled. M3 contains one narrowly selected, source-traceable `TEMP_REFERENCE` wave extracted from the user-supplied build for local testing. Every export preset excludes `assets/reference_only/`. Only owned or licensed final content may be placed under `assets/production/`.

## Supplied-build asset catalog

`docs/unity_asset_catalog.csv` contains 14,932 indexed records from the supplied build, including meshes, textures, sprites, materials, animations, audio, scripts and gameplay-relevant GameObjects. `docs/unity_asset_summary.json` is the machine-readable summary.

## M3/M4 asset waves

`assets/reference_only/m3_wave1/manifest.json` records the source file, Unity Path ID, output file and classification of every extracted reference. In a local debug run, `ReferenceVisualAdapter` swaps the procedural vessel visuals for the extracted Clipper hull, sails and port/starboard cannons when those files exist. Release exports retain the procedural/production fallback because reference files are excluded.

M4 adds `assets/reference_only/m4_wave2/`: Barco, NPC Chalupa, Island 04 Main/Coast/Bottom and a wooden pier. `ReferenceVisualAdapter`, `ReferenceIslandAdapter` and `ReferencePortAdapter` load them dynamically in local debug runs only.

M8 turns the recovered data into visible runtime content. The supplied Clipper, Barco, Chalupa, tropical, desert and snow island assets, harbor pier, lighthouse, water textures and audio are now loaded in Web/Mobile/Desktop test exports instead of remaining debug-only references. The IL2CPP metadata analysis is preserved under `docs/il2cpp/` and mapped to the Godot systems in `docs/M8_IL2CPP_IMPLEMENTATION_MAP.md`.

M9 maps the recovered `UIShipSelector`, `ShipData`, `PlayerShipSpawner` and equipment contracts into an offline harbor roster. The three recovered ship families can now be browsed, bought, equipped and saved. See `docs/M9_REPORT.md` and `docs/M9_IL2CPP_IMPLEMENTATION_MAP.md`.

M10 added offline sector encounters based on the recovered spawner/admiral/reward contracts. Its historical 4.5.1 results remain in `docs/M10_REPORT.md`. Current engine verification is described in `docs/GODOT_4_7_2_MIGRATION.md`; run `python3 tools/run_engine_checks.py --engine /path/to/godot` to repeat it. Native device exports require separate validation.

M11 adds the ammunition/consumable inventory, cannon and deck equipment, native arsenal UI and eight newly decoded original images. Six are used in the arsenal; shield and gunpowder images are reserved, not implemented abilities. Base resupply remains a test convenience. See `docs/M11_REPORT.md` for exact original evidence versus inferred behavior, tests, source object IDs and remaining gaps. **I** opens the arsenal anywhere; purchases require harbor proximity. **F** docks, repairs and restocks iron ammunition. **X** cycles ammunition; **Q/E** use repair/boost stock.

M12 adds a prebuilt single-thread Web preview, restricted local HTTP launcher,
automatic rebuild/reload option, Cursor startup rules, and a separate WebSocket
transport probe. It does **not** implement shared multiplayer gameplay. See
`docs/M12_CROSSPLAY_PLAN.md` for the distinction and target readiness.

See `docs/M3_REPORT.md` through `docs/M12_REPORT.md` and their supporting previews/reports for implementation details.


## M23 Product Direction Lock
Visual master: the project-owned naval fantasy gameplay mockup. Gameplay depth target: modern persistent naval action inspired by the system richness of classic browser/mobile sea-combat games, implemented with original UI, assets, names and balancing. M23 starts this convergence with readable NPC classes/levels/rarity and boss salvage.

## M24 Combat Depth Pass
M24 expands the reconstructed naval combat into a more tactical, modern broadside loop while preserving the project-owned mockup as the visual master. Cannon classes now have role/range profiles; ammunition has range, critical and tactical roles; effective range is derived from cannon + ammunition; target HUD reports optimal/edge/out-of-range state; and NPC archetypes dynamically choose ammunition and preferred engagement distance instead of using one fixed firing envelope. This is an original implementation inspired by persistent naval action system depth, not a direct code/content copy from another title.


## M25 Encounter Ecology + Boss Hunt Pass
M25 extends the modern persistent naval-action direction without changing the project-owned mockup as the visual master. Enemy ships now use explicit PATROL/PURSUE/ENGAGE/RETURN states with spawn anchors, safe-zone disengagement and leash limits so NPCs do not chase indefinitely across a sector. The final regular slot in each sector is promoted to an actual stat-scaled elite. Bosses gain three health-driven combat phases. Tropical sectors now culminate in an original procedural Tide Leviathan monster hunt, while other biomes retain admiral ship bosses. Loot now has common/uncommon/rare/epic/legendary tiers with distinct native chest presentation and reward multipliers. These systems are original reconstruction/game-design work; no third-party gameplay code or UI is copied.


## M29 Fleet Command + Event Loop Pass
M29 keeps the project-owned naval-fantasy mockup as the visual master and extends the modern persistent-sea-combat direction into the surrounding product shell. The top navigation no longer points only to placeholder notices: Events, Quests, Market, Guild, Chat, Achievements, Rankings, Bonus, Group and Captain Menu now open a shared responsive in-game menu layer. The layer pauses steering/navigation, keeps fast page switching, uses larger touch geometry, and adds a compact bottom tab bar for small/portrait displays. Content is intentionally offline-safe: no fake server players, guild members, chat messages or rankings are fabricated. Shipyard, Arsenal, minimap/world map and combat remain separate authoritative gameplay surfaces.

M29 explicitly treats menu architecture, mobile comfort and screen composition as first-class reconstruction work alongside combat/world systems. Future online services can bind to these views without replacing the mobile/desktop presentation contract.


### M29 additions
- The Captain menu now renders card-based Command Deck pages rather than line-only placeholder copy.
- Quests now include persistent Daily and Weekly objectives for sinks, salvage and harbor visits.
- Daily/Weekly rewards can only be claimed after all objectives are complete; claim state persists in the save payload.
- Event points accumulate from normal gameplay records and feed the Events presentation.
- Events page now exposes Pirate Hunt, Leviathan Hunt and Admiral Alert presentation cards.
- Compact/portrait navigation uses five large bottom tabs: Events, Quests, Market, Guild and Menu.
- Menu input continues to cancel sailing/navigation so mobile taps cannot leak into the world.

Validation in the reconstruction environment: `tests/test_m29_contract.py` = 3/3 PASS. Older milestone tests that hard-code M22/M25 version labels are intentionally not release gates for M29. A Godot 4.7.2 executable is not installed in the build environment, so an engine parse/export must still be run on a Godot-equipped machine before visual acceptance.

### M29 Fleet Command additions
- Event milestones at 100 / 250 / 500 points with persistent one-time reward claims.
- Event rewards grant real Gold and EXP through the existing progression system.
- A lightweight persistent quest-chain stage advances from actual combat activity.
- Event presentation now reflects player progress instead of fixed decorative values.
- Harbor Market presentation clearly separates port-only purchasing from at-sea inventory.
- The project-owned mockup remains the visual master across desktop, web and mobile composition.
