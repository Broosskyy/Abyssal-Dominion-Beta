# Frontier expansion after data update 242

The Android bootstrap advances to **305902 / 0.305.9-test.2** because the installed updater now opens the graphical welcome screen rather than entering the sea directly. Existing package and signing identity remain unchanged. A replacement APK is required for this new entry flow. The signed data pack also requires APK 305902, so older apps cannot mount the expansion before updating their launcher. Subsequent game-only changes keep using signed data updates.

## Implemented

- Illustrated updater → welcome/login/register → captain harbor → user presses **Zur See** → a single chart-loading curtain → sea. Welcome and captain harbor are interactive pages, not a second progress screen. The sea menu can return to the captain harbor.
- One **Items** selector beside ammunition, with all eight consumables, inventory, effects, toggle state and live cooldowns. The four former permanent supply orbs are hidden. Existing keyboard shortcuts 4–7 remain.
- Windtrank (+25% speed, 20s), Nebelbombe (−30% received projectile damage, 8s), Befreiungsrum (remove slow), Bergungsamulett (+20% loot gold, 60s), with real stock consumption, cooldowns and original SVG icons. Harbor stock sells each item. Test balancing values remain in `content.gd`.
- Forty standard seas **1/1, 1/2 ... 20/1, 20/2**, all visible in both maps menus. Stable original ids 0–5 remain intact, including three bonus maps; new public seas append ids 6–42. Portals link paired lanes and neighboring difficulty tiers. Every sea has a reachable harbor and connected exits. The map details plot the next adjacent portal toward a selected distant destination. Additional seas use deterministic biome/tint/layout variants of the existing island geometry, not forty separately authored worlds.
- Original generated transparent harbor, guild-island base and four independent tower sprites, plus a cinematic entry background. Harbor and guild-island collision contours are derived from their actual opaque silhouettes. The harbor cove stays navigable; patrols cannot sail through the new land. Source images and generation descriptions are recorded under `assets/world_v2`.
- Nineteen guild islands: original 3/1 plus every paired lane-2 sea from tier 3 through 20. Existing tower combat and conquest apply. Each island keeps its own owner duration and ten upgrades, levels 1–5; ownership cannot leak into another map. Upgrades spend gold and raise real tower HP/damage. This is local simulated conquest until the guild server is connected.
- Profile uses a saved **player name**, with pirate-rank icon on the left, yellow guild tag and Battle-Point icon on the right. Zero BP displays an unranked grey emblem. NPC kills do not award PvP points.
- Saved daily rewards with a seven-day sequence and one claim per UTC day; capped eight-hour offline gold/ammunition reward, collected once. Saving commits claim state before a scene transition. Local beta rewards never become trusted online currency.
- Settings split into **Grafik / Steuerung / HUD / Effekte**. Touch scrolling respects scaled coordinates, finger ownership and canceled touches; app suspension clears sea gestures and double-tap state.
- Account API and cross-platform WebSocket client/server preparation; see `server/README.md` for exact implemented and remaining online scope. No public MMO or online combat is claimed.

## Verification

`frontier_test.gd` covers forty-map topology and navigability, migration, expanded bonus return, effect duration/stock, per-island tower upgrades, once-only rewards and responsive entry/menu layouts. The existing simulation, navigation, effects, ammo, updater and UI suites remain mandatory. `frontier_capture.gd` captures sixteen actual OpenGL-rendered views at 2340×1080, 844×390 and 1080×2340; native builds attach these to the release. Tests do not substitute for physical Android/iOS or public multi-device acceptance.

## Feedback after update 243

- Restore the familiar classic coastal island beneath ten independent defenses, rather than the fixed castle illustration. The guild island is 2.05 times the base chart width; art and collision scale together. Land-only emplacement selection keeps every pair of towers at least 100 world units apart on all nineteen guild maps. Four cannon, three mortar, two chain and one guardian tower retain the four original role IDs. All ten are individually upgradeable to level five, participate in conquest and persist per island. Legacy four-slot saves keep their first four upgrade levels and append six level-one slots.
- Single enemy selection never arms fire. A simulation-level target switch disarms the previous attack. Android's synthetic mouse event cannot count as an extra world tap; a configurable double-tap attack requires two distinct taps 70–360 ms apart. The FEUER button remains the explicit attack control.
- Animated coastal foam, tower pennants, torch flicker, shot smoke and muzzle flashes keep the defenses readable as separate objects. The captain-harbor backdrop animates open-water ripples and highlights while leaving the ship and pier rigid. Existing ship motion, wakes and combat effects remain active according to the player's settings.
- Renderer evidence includes paired animation phases for the captain harbor and guild island. This game-only pass keeps bootstrap APK 305902 and ships through the signed data updater.

Local verification uses the available Godot 4.6.3 engine; release CI imports, checks and packages with the project's pinned Godot 4.7.2. Physical Android acceptance is still separate from automated checks.
