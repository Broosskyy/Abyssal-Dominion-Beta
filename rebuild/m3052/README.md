# Abyssal Dominion M3054 — ship rendering fixes and audit

The active Godot 4.7.2 project remains in `rebuild/m3052/` to preserve the existing Android app identity and upgrade path. Current version: `0.305.4-test.4` / Android code `305404`. M3052 is retained in Git history and `releases/M3052/`.

## Aktuelle Vorgabe: 2D zuerst

Wir stabilisieren zunächst den bestehenden 2D-Spielkern. 3D-Modelle und ein Wechsel der Rendertechnik sind für diese Phase nicht vorgesehen. Ein Referenzschiff mit vorhandenen Richtungsbildern dient zur Prüfung von Fahrt, Zielwahl, Kampf, Beute, Hafen und Speichern, bevor weitere Designs ausgebaut werden. Vergleich, offene Grafikgrenzen und Abnahmekriterien stehen in [2D zuerst](../../docs/design/2D_FIRST.md).

## M3054 ship rendering changes

Analysis of `206697.mp4` and the actual source sprites identified reflection-origin jumps, a non-clockwise atlas order, unequal transparent padding, generic misplaced hull pivots and detached wake/shadows. M3054 draws every ship from measured visible bounds and a per-frame opaque hull pivot. Reflection uses a canvas transform around that pivot, with positive destination rectangles. Four-heading atlases use explicit ordering and course hysteresis. Shadows, selection rings, hit origins and compact wake strokes share the logical waterline point. Default camera zoom is about 17% closer. Shipyard previews use trimmed frames.

All 26 original PNG ship sources are unchanged. `assets/visuals/ship_frames.json` records 74 measured healthy frames and their source digests; the exact metadata is verified inside the APK. The ten concept ships have one source perspective, rendered with reflection, while the sixteen reference hulls have four authored views. These are identified accurately in the shipyard. Missing true perspectives are not synthesized by this fix.

See [`docs/m3054/SHIP_RENDER_AUDIT.md`](../../docs/m3054/SHIP_RENDER_AUDIT.md) for video timestamps, causes and limits. CI includes renderer regressions, three galleries rendered through the actual runtime draw function, and an east/west maneuver video.

## Existing playable content

- Three connected regions: Caribbean Sea (level 1), North Sea (level 2), Shadow Waters (level 4). Regional island art, mirrored layouts, ocean tint and increasingly strong enemies. East/west portals require physical sailing and six seconds without damage. Returning during a session preserves previous enemy and loot state.
- Physical harbor marker, docking, departure, paid drydock repair and four functional equipment categories with three purchased tiers: cannon/chain damage, harpoon damage, maximum hull HP and sailing speed. Docking pauses local combat.
- Captain XP and levels 1–20, with seven sequential quests for combat, salvage, monsters, exploration and elite ships. Rewards are claimed once; previous achievements count toward subsequent tasks.
- Four visual loot categories and equipment/quest/map icons extracted from the supplied 110-PNG reference collection. Seventeen additional cropped runtime images, including a panel frame; all 60 PNGs have provenance and SHA-256 checksums. Full reference boards are not copied into runtime as backgrounds.
- Guest save schema 2 persists level, XP, equipment, quest counters, visited regions, current region, position and hull. Schema-1 M3052 saves retain wallet, ammunition, design and claimed first quest. Existing app package, signing cache and save filename are retained.

## Controls

Tap water to sail and an enemy to select it. FEUER toggles cannon fire. Harpoons target monsters; cannon/chain target ships. Sail over chests to collect them. HAFEN opens harbor services and sets a route to the dock; the contextual button docks, departs or enters a nearby portal. LOGBUCH shows quests. KARTEN sets a course to unlocked portals. Pinch/wheel zooms, drag/right-drag pans and ZIEL recenters.

## Build and verification

`.github/workflows/m3052.yml` builds `releases/M3054/ABYSSAL_DOMINION_M3054_REBUILD_ARM64.apk`. The builder audits every PNG, imports and tests the project, verifies embedded textures, ARM64 engine, signature, 16 KB alignment and application/version identity. CI also captures actual gameplay at desktop and mobile landscape sizes; no generated mockups serve as QA evidence. Build reports record the source commit. Simulation, progression and UI tests use fresh isolated guest storage.

## Scope

Local guest gameplay. This scene is not connected to M3051's separate development server. Public networking, accounts, multiplayer/PvP, guilds, cross-device acceptance, production signing and an updater remain open. Three regional layouts share a base geometry transformed per region; this is not a claim of three entirely independent authored worlds. NPC state on other maps is retained during the current session, not serialized across app restarts. Captain level and equipment are functional; cosmetics are still free test designs.

Supplied/reference art is used in the private development repository; public redistribution rights have not been established. Automated checks and rendered captures do not constitute a physical Android device playtest.
