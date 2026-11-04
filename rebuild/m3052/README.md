# Abyssal Dominion M3059 — signed data updates and 2D sea foundations

The active Godot 4.7.2 project remains in `rebuild/m3052/` to preserve the existing Android app identity and upgrade path. Current version: `0.305.9-test.1` / Android code `305901`. M3052 is retained in Git history and `releases/M3052/`.

## M3059 foundations

One final bootstrap APK adds RSA-authenticated game-data ZIP updates: compatible game code/graphics can update without Android installation. Native/updater changes still require an APK. Legacy four-view NPCs sail actual alternating diagonals, while eight-view and future 3D metadata retain free courses. Measured island silhouettes replace displaced circular collisions, large island overlays are removed, water waves animate directionally and ammunition buttons show type/stock/selection. See [behavior and acceptance limits](../../docs/m3059/FOUNDATION.md).

## M3058 video regressions

Submitted recordings 206805/206806/206807 show an opaque chest used as a chart portal, stacked damage numbers and harbor content reaching into its decorative frame. Gates now use transparent chart rings, navigation captions yield to nearby ships, damage text totals a short volley without changing simulation damage, and the decorated panel has a deeper safe scroll inset. Phone-sized runtime captures retain the project canvas stretch at 2340×1080. Existing low-resolution NPC art and four-view limits remain open; no new ship art is claimed. See [video audit](../../docs/m3058/VIDEO_AUDIT.md).

## M3057 updater

Android launcher and HAFEN → UPDATES PRÜFEN now use a native DownloadManager bridge based on Realm 733. Files are verified before Android installation; gameplay and guest storage stay available. One manual bootstrap install is required. The existing repository is now public; verified APKs are published as GitHub releases before the latest-version manifest is updated. See [updater flow and limits](../../docs/m3057/UPDATER.md).

## Aktuelle Vorgabe: 2D zuerst

Wir stabilisieren zunächst den bestehenden 2D-Spielkern. 3D-Modelle und ein Wechsel der Rendertechnik sind für diese Phase nicht vorgesehen. Ein Referenzschiff mit vorhandenen Richtungsbildern dient zur Prüfung von Fahrt, Zielwahl, Kampf, Beute, Hafen und Speichern, bevor weitere Designs ausgebaut werden. Vergleich, offene Grafikgrenzen und Abnahmekriterien stehen in [2D zuerst](../../docs/design/2D_FIRST.md).

## M3056 paired damage state

The Small Starter now has eight intact and eight damaged 2D views. At positive hull HP of 35% or less, the renderer uses torn sails; above that local test threshold it uses intact sails. Repair immediately restores the intact image when the threshold is crossed. At zero HP the actor is not drawn as an afloat ship. This is a damaged-but-afloat state, not eight sinking animations.

Both states use fixed magnification and paired waterline anchors. Lower-hull image registration found zero or one source pixel of translation; the NE and SE damaged pivots compensate one pixel. Generated textural differences remain possible. Gallery pages 3/4 and a dedicated health_state_change.mp4 capture the actual runtime states and repeated damage/repair transitions. See [damage receipt](../../docs/m3056/STARTER_DAMAGE.md).

## M3055 Small Starter

The new Küstenschaluppe uses the stable ID SHIP-STARTER-001 and saved design index 26. It has eight generated intact 2D headings: N, NE, E, SE, S, SW, W and NW. Fresh guests start with it; existing saves retain their selected design. It is selectable in HAFEN → Werft, labeled 8 ANSICHTEN. All previous 26 designs and source images remain available.

Explicit sprite bounds and reviewed hull anchors share one fixed magnification across all eight headings, preserving natural foreshortening. Heading hysteresis avoids rapid switching at sector boundaries. The starter is displayed smaller than larger test designs. No model or 3D runtime has been introduced.

This is the first integrated art candidate, with generated detail/proportion differences still subject to review. M3056 adds the damaged sail set; the other 26 test designs retain their existing presentation. See [asset receipt](../../docs/m3055/STARTER_SMALL_8.md) and [Seafight design comparison](../../docs/design/SEAFIGHT_DESIGN_COMPARISON.md). CI captures all eight headings through the actual runtime renderer (gallery page 3), plus the existing maneuver video and gameplay captures.

## M3054 ship rendering changes

Analysis of `206697.mp4` and the actual source sprites identified reflection-origin jumps, a non-clockwise atlas order, unequal transparent padding, generic misplaced hull pivots and detached wake/shadows. M3054 draws every ship from measured visible bounds and a per-frame opaque hull pivot. Reflection uses a canvas transform around that pivot, with positive destination rectangles. Four-heading atlases use explicit ordering and course hysteresis. Shadows, selection rings, hit origins and compact wake strokes share the logical waterline point. Default camera zoom is about 17% closer. Shipyard previews use trimmed frames.

All 26 original PNG ship sources are unchanged. `assets/visuals/ship_frames.json` records 74 measured healthy frames and their source digests; the exact metadata is verified inside the APK. The ten concept ships have one source perspective, rendered with reflection, while the sixteen reference hulls have four authored views. These are identified accurately in the shipyard. Missing true perspectives are not synthesized by this fix.

See [`docs/m3054/SHIP_RENDER_AUDIT.md`](../../docs/m3054/SHIP_RENDER_AUDIT.md) for video timestamps, causes and limits. CI includes renderer regressions, three galleries rendered through the actual runtime draw function, and an east/west maneuver video.

## Existing playable content

- Three connected regions: Caribbean Sea (level 1), North Sea (level 2), Shadow Waters (level 4). Regional island art, mirrored layouts, ocean tint and increasingly strong enemies. East/west portals require physical sailing and six seconds without damage. Returning during a session preserves previous enemy and loot state.
- Physical harbor marker, docking, departure, paid drydock repair and four functional equipment categories with three purchased tiers: cannon/chain damage, harpoon damage, maximum hull HP and sailing speed. Docking protects the moored captain while NPC patrols keep moving.
- Captain XP and levels 1–20, with seven sequential quests for combat, salvage, monsters, exploration and elite ships. Rewards are claimed once; previous achievements count toward subsequent tasks.
- Four visual loot categories and equipment/quest/map icons extracted from the supplied 110-PNG reference collection. Seventeen additional cropped runtime images, including a panel frame; all 62 PNGs have provenance and SHA-256 checksums. Full reference boards are not copied into runtime as backgrounds.
- Guest save schema 2 persists level, XP, equipment, quest counters, visited regions, current region, position and hull. Schema-1 M3052 saves retain wallet, ammunition, design and claimed first quest. Existing app package, signing cache and save filename are retained.

## Controls

Tap water to sail and an enemy to select it. FEUER toggles cannon fire. Harpoons target monsters; cannon/chain target ships. Sail over chests to collect them. HAFEN opens harbor services and sets a route to the dock; the contextual button docks, departs or enters a nearby portal. LOGBUCH shows quests. KARTEN sets a course to unlocked portals. Pinch/wheel zooms, drag/right-drag pans and ZIEL recenters.

## Build and verification

`.github/workflows/m3052.yml` builds `the versioned APK in GitHub releases`. The builder audits every PNG, imports and tests the project, verifies embedded textures, ARM64 engine, signature, 16 KB alignment and application/version identity. CI also captures actual gameplay at desktop and mobile landscape sizes; no generated mockups serve as QA evidence. Build reports record the source commit. Simulation, progression and UI tests use fresh isolated guest storage.

## Scope

Local guest gameplay. This scene is not connected to M3051's separate development server. Public networking, accounts, multiplayer/PvP, guilds, cross-device acceptance, production signing and physical updater acceptance remain open. Three regional layouts share a base geometry transformed per region; this is not a claim of three entirely independent authored worlds. NPC state on other maps is retained during the current session, not serialized across app restarts. Captain level and equipment are functional; cosmetics are still free test designs.

Supplied/reference art is used in the private development repository; public redistribution rights have not been established. Automated checks and rendered captures do not constitute a physical Android device playtest.

## Portal travel and nautical HUD

Tap a portal or choose its course from the map panel to sail there and cross automatically. Level gates explain their requirement; recent damage delays the queued crossing until six seconds without damage. A new water course, docking, repair or sinking cancels the order. Map arrival updates the camera and guest save.

The HUD uses six functional illustrated navigation cells, a framed coordinate minimap, round fire/repair/ammunition controls, a contextual ammunition list, HP/XP quick-slot deck and live System/Quest tabs. The ten source SVG icons are recorded under `vector_ui` in the asset provenance file. The layout follows the supplied Seafight/Battle of Sea and Abyssal mockup references; it does not introduce fictional online chat, guild currency or unimplemented consumable powers.

## Responsive HUD polish

The HUD now scales independently from the sea camera and canvas. At 720 logical pixels high, the default comfortable profile enlarges the complete HUD by 20%; short phone layouts are capped to retain nonoverlapping touch targets. Menu → Anzeige & HUD anpassen offers compact, comfortable and large profiles and an optional quest/system window. Preferences live in a separate local display file; captain saves, sailing positions and world camera coordinates are unchanged. The primary fire caption, navigation labels, quantities and ship cards have larger text, and circular controls use brass fasteners and a glass highlight.

Acceptance includes all three profiles at 1280×720, 1560×720, 844×390 and 720×405: control bounds, touch separation, scaled hit testing, menu containment, full-size ocean, display preference reload and unchanged captain progress. Actual renderer captures add a large-HUD view and the display settings panel. This update changes compatible game scripts only and uses the signed data channel; it does not require a replacement APK.

## Combat HUD and water polish

The wide-screen quick deck is grouped beside the right-hand combat buttons. Ammunition keeps its direct quick slots and contextual chooser; the chooser no longer repeats the selected stock. Cyan selection rims, larger type captions, brass cornerwork and shaded navigation cells distinguish active controls. Ship names have their own title line, with captain level moved into the HP readout.

The fire orb previews actual readiness: target required, incompatible weapon, insufficient volley stock, range, blocked shot, reload and docking. This is presentation only: refreshes do not consume ammunition or start pursuit. The existing attack toggle and simulation damage remain unchanged. The ocean adds a third scrolling noise sample for finer surface normals and sparse highlights, with reduced broad wave bands. Source NPC sprites retain their existing resolution.

## Camera thumbpad and safe target cycling

A single-owner touch joystick pans only the camera; the ship retains its tap-to-sail course. Neutral release, opening a menu, app pause, focus loss and recenter cancel held input. After panning, the view stays at its inspected world location while the ship sails; recenter resumes ship following. The control can be hidden in display settings and is remembered separately from captain progress. The wide quest panel sits above it; on short displays quests remain accessible through top navigation, with the tracker restored when the pad is disabled.

The circular arrows beside recenter, or desktop Tab, cycle living targets visible outside HUD-covered areas. Cycling stops existing fire, does not change ammunition or chase a target, and reports an empty view. New art is an original scalable SVG with checksum provenance. Automated UI acceptance covers touch ownership, second-finger isolation, release, menu cancellation, camera-only movement, preferences and target cycling. Actual renderer captures include a held thumbpad pan with a machine-readable ship-position receipt.

## Compact edge HUD and cannon action

The header is a single gold line beside the navigation cells, with status on the right of short screens so it does not cover the centered ship name. Captain HP and XP stay on the left card only; the combat deck no longer repeats them, and the world bar under the captain is omitted during play. The fire control is a larger free-standing button using an original cannon graphic. The quest window is shorter. The shipyard shows all 27 designs as named cards, sorted by name. Ocean shading uses broader waves and less high-frequency fiber. Target text is clipped inside its card.

## Seafight-style HUD v2, sea chart and loading screen

The top bar now spans the screen: gold and sunk-ship wallet on the left, eight painted navigation tiles (Schiff, Werft, Hafen, Aufträge, Karten, Vorräte, Rangliste, Menü) and framed EXP/HP bars with exact numbers on the right. The sea carries a chart ruler with column numbers and row letters matching the framed minimap header (`(1-1) X: 13 Y: J`, 144 world units per square); zoom, recenter and display settings sit on the minimap corners. The quest tracker is a single strip that opens the logbook, with ABHOLEN only when a reward is ready. The combat corner is an L around a large FEUER cannon: ammunition and repair orbs above and beside it, target spyglass, supplies and weapons along the bottom edge. Status messages are a centered pill sized to their text, and the logbook keeps the last six messages.

Nameplates use one readable size, faction colors, a framed HP bar and a winged rank emblem. The new Rangliste window summarizes local captain statistics until the online ranking exists. Display settings add a helm mode in which the joystick steers the ship directly instead of panning the camera. Region crossings and game start show a loading screen with a painted harbor, a turning helm wheel, a brass progress bar and rotating tips; taps are ignored until it fades.

The water is a brighter royal blue built from a seamless 512 px tile (`tools/make_sea_tile.py`, reproducible with seed 3059) sampled twice at different scales and drift, with slow swell and faint twinkles instead of repeated highlight strokes. All twelve painted HUD icons, the loading backdrop and the sea tile are original art for Abyssal Dominion and are recorded with SHA-256 under `vector_ui` in the asset provenance file. This update changes game scripts and data only and ships through the signed data channel; it does not require a replacement APK.
