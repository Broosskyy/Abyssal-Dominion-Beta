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

`.github/workflows/m3052.yml` builds the versioned APK (published as a GitHub release) and the signed data pack; renderer captures are attached to each `data-N` release. The builder audits every PNG, imports and tests the project, verifies embedded textures, ARM64 engine, signature, 16 KB alignment and application/version identity. CI also captures actual gameplay at desktop and mobile landscape sizes; no generated mockups serve as QA evidence. Build reports record the source commit. Simulation, progression and UI tests use fresh isolated guest storage.

## Scope

Local guest gameplay. This scene is not connected to M3051's separate development server. Public networking, accounts, multiplayer/PvP, online guilds with members, cross-device acceptance, production signing and physical updater acceptance remain open. Three regional layouts share a base geometry transformed per region; this is not a claim of three entirely independent authored worlds. NPC state on other maps is retained during the current session, not serialized across app restarts. Captain level and equipment are functional; cosmetics are still free test designs.

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

## Seafight systems: shield, supplies, decks, Kessel, bonus maps, Kastelle and guild fortress

Every ship, including the captain, has separate hull and shield. The captain's nameplate shows the guild tag in gold, the name, a rank medallion, a green hull bar and a blue shield bar with exact numbers, plus a status row for active powder, plates, blessing, tide deck, guild hold and slow. Enemy plates show hull and, where present, shield. Plates keep their on-screen size when the camera zooms out. The top bar adds a SCHILD meter under EXP and HP.

Ship supplies sit as orbs around the attack button. Black powder (+40 % salvo damage) and armor plates (−35 % damage taken) are toggles; powder is consumed only by a valid salvo and plates only by a received hit. Emergency repair and shield charge are instant with their own cooldowns. Basic repair never consumes an item. A pager button next to the ammunition (or Q) switches the corner between page 1 (ammunition) and page 2 (supplies); keys 4–7 use the supplies directly. Active effects appear as chips with timers under the target card.

The harbor sells supply packs and cannon slots and opens the deck yard: five deck types (cannon, armor, hunter, navigation, logistics) in three tiers, one of each type mounted at a time. The cannon deck raises cannon capacity. The Gezeitendeck is a timed bonus deck counted in sea time, and Kristallsegen is the single major blessing. Kastelle are six permanent harbor investments up to level 8 (Bugkastell, Heckkastell, Mastkastell, Mannschaftskastell, Jagdkastell, Kriegskastell) with rising costs and captain level gates.

Tide essence comes from quests, sunk ships and sparkles on the sea. In the Gezeitenkessel it is thrown in batches of 1, 5, 10 or 25 against a published pool with visible weights; every throw advances a 100-step meter with fixed rewards at 10, 25, 50 and 100, a daily free flask is available, and duplicate decks convert to essence. Bonus maps (Bronze from level 2, Silber from 5, Gold from 8) are assembled from scroll fragments and run as separate instances with five waves (opening, pressure, elite, admiral, leviathan). A cleared wave is a checkpoint: sinking restarts that wave instead of spending lives, and BONUSKARTE VERLASSEN returns to the previous sea with progress kept.

A local guild can be founded from the Gilde window (name and a tag of two to four letters or digits, 300 gold; marked "lokal" until the online server exists). The Korsarenfestung in the Schattengewässer is defended by cannon, mortar, chain and guardian towers. Sinking all four pays gold, essence and scroll fragments; with a guild, the island is then held for 30 minutes, during which the rebuilt towers carry the guild tag, no longer fire at the captain and loot gold rises by 10 %. Without a guild the towers return after three minutes. Towers have their own world sprites, plates and minimap markers.

The navigation row now has nine tiles: Schiff, Werft, Hafen, Logbuch, Bonus, Kessel, Gilde, Rang and Menü, with badges for claimable quests, ready bonus scrolls, the free flask and remaining guild hold time. The helm mode from the previous update is removed: the joystick pans the camera only and the ship sails by tapping the sea, as the design lock requires. Twenty painted icons and sprites and a painted cauldron scene are original art for Abyssal Dominion, recorded with SHA-256 under `vector_ui` in the asset provenance file. Save schema 3 migrates schema 1 and 2 saves. This update changes game scripts and data only and ships through the signed data channel; it does not require a replacement APK.

## M3061 menus, cauldron throw, world chart and local staff tools

Menus use a carved window: lacquered hull-blue body, brass corners, a title ribbon and bevelled buttons, cards and tabs. Lists scroll with the finger even when the drag starts on a button. The list keeps gliding after release, a drag never activates the button underneath, and a tap without movement still does. Reopening a menu restores the scroll position once the new content is measured.

The Gezeitenkessel plays the throw: flasks arc into the cauldron, the brew flashes in the best rarity colour and the rewards rise out of the mouth. The same throw continues if the window is rebuilt. Deck gems sit under the captain's bars on the sea and under the hull in the Schiff window, one gem per slot plus the tide deck, with chevrons on either side.

Seekarten opens a parchment world chart of the three portal seas, the Korsarenfestung and the three scroll-only bonus seas. The ANLEITUNG tab explains the chart squares (one square is 144 m, columns numbered, rows lettered), portal travel, harbours, hostile and neutral colours, bonus maps and the minimap legend.

Staff tools are role based. In this local test build the codes ADMIN-3060, GM-3060, MOD-3060 and QA-3060 sign in an administrator, game master, moderator or QA (case and dashes are ignored). Official presence shows the role badge on the nameplate, an aura around the ship and a marker on the minimap. Ghost and spectator hide that badge and draw the hull faded; spectator cannot fire. Teleport covers harbours, portals, the fortress, other seas and a tap-to-jump mode. Spawns, grants, ship flags and target tools are limited by role, and every privileged action is written to the audit log. Staff kills and staff bonus runs never score. Signing out can restore the snapshot taken at sign-in or keep the changes and mark the save. These codes and the local staff file are for testing only. Real staff rights will be issued by the server; moderation of other captains stays disabled until that server exists. Five new painted icons and the chart parchment are original art, recorded under `vector_ui`. This update changes game scripts and data only and ships through the signed data channel; it does not require a replacement APK.

Desktop opens a 3840×2160 window and phones use the device's own pixels. The picture is no longer a 1280×720 canvas stretched up, so the interface and the sea stay sharp on a phone and on a 4K screen. Patrols sail slower and hold a long straight leg instead of picking a new direction every few seconds. Leuchtkugeln mark a target, Kürbismunition splinters nearby ships, Schneemunition slows hard and Eismunition freezes a ship for a few seconds. Test captures keep their own sizes. The sea keeps the painted tile, but samples it finer and sharpens the grain so the water is no longer a soft wash. Thin crests run across the swell. The default camera sits closer, so ship sprites use more of their source pixels. Deck gems under the nameplate are larger, with the tier numeral inside, and an active Kristallsegen hangs beside them as its own crystal with a running timer. Concept-ship sources remain the small supplied paintings; they are not replaced by higher-resolution hulls in this pass.


## Sea-chart reference polish

The next data update follows the supplied Seafight/Battle of Sea footage with quieter navy/teal water, compact hull/shield nameplates and small rank marks. Caption placement reserves clear space for the captain and selected target and avoids live hulls, other captions and HUD controls. Mounted deck marks move to an edge strip; exact values remain in the top HUD and target card. Special ammunition uses an aligned combat grid and opaque-core previews instead of displaying the source checkerboard. New status messages expire after four seconds, with docking instructions retained. The existing cannon, ammunition, supplies, camera and progression behavior is preserved. See [reference pass and verification limits](../../docs/m3062/REFERENCE_POLISH.md).

## Ten decks under the ship, fixed readouts and brighter water

The supplied data-50 device screenshots correct the previous presentation direction: the captain's name, HP, shield and decks now stay together at a fixed waterline anchor. Nearby hulls never push that block across the sea. Covered NPC captions yield while their selected-target details stay available in the HUD. The captain title grows from 12 to 15 px and the HP bar from 72×3 to 112×8; screen size remains stable when zooming.

Ten physical deck slots are shown directly below the bars in two rows of five. Gold decks are orange/yellow, Elite blue and Kristall purple, independently of their equipment role. Purchased copies can share a role, but each physical deck occupies only one slot. The harbor deck yard mounts, removes and upgrades individual decks; Elite opens at level 3, Kristall at level 8. Gezeitendeck, Sturmdeck, Bergungsdeck and Kristallsegen use separate surrounding wave/lightning/anchor/crystal symbols; inactive effects remain dim. Sturmdeck adds 12% speed, Bergungsdeck 15% loot gold, with actual purchases and saved sea-time durations.

Save schema 4 migrates schemas 1–3 and retains the two existing deck slots and values, leaving eight new slots empty. The left-edge deck strip is removed. Water is brighter blue/teal, and short phones group special ammunition into a 2×2 grid beside the combat controls to leave space beneath the ship. [Comparison, economy values and acceptance evidence](../../docs/m3063/DECK_REFERENCE_COMPARISON.md).


## M3064: one ammunition selector and point decks

Regular decks now appear as two rows of five material-colored points below name, HP and shield, with special-deck icons around them. One MUNITION button opens all seven ammunition types; selecting a row activates it and closes the list. Four persistent special-ammo buttons and paging are removed. MSDF text and imported texture mipmaps improve scaled rendering; legacy low-resolution NPC artwork remains a source limitation. See [presentation and verification](docs/m3064/AMMO_AND_DECK_PRESENTATION.md).


## M3065: reference status and metal deck fittings

The supplied close-up supersedes the small circular markers from M3064: ten beveled rectangular deck fields now sit below the name, separate HP number, straight HP bar and additional shield bar. A pirate crest and broad steel special-deck fittings surround the grid, with coloured inlays only for active effects. See [reference details](docs/m3065/REFERENCE_STATUS_AND_DECKS.md).


## M3066: quieter ship readout and persistent captain ID

The captain nameplate is moved farther below the hull, with a translucent local ID beneath the name. Numeric HP is removed from the ship (the HUD continues to show it); green HP and blue shield gauges remain separate, followed by all ten existing regular deck slots and their special fittings. Rank placement measures the actual high-DPI text size before applying a larger clearance. The local captain ID is generated once and saved in schema 4 without changing combat, inventory, decks, or the data updater; until multiplayer accounts are implemented it is not a server-issued identity.


## M3067: ship silhouette-aware labels and original vector deck polish

Captain and NPC nameplates now start below the current visual frame's lowest point, with 34/24 screen-pixel clearances. Changes in heading or sprite size cannot push the ship into its own name; the captain's layout is independent of nearby ships. Selected and ordinary NPC captions are always drawn, and deterministic adjacent slots resolve overlap instead of suppressing NPC names/HP bars. Only real players show pirate-rank insignia. Island names use smaller, zoom-independent typography. Existing HP/shield/deck semantics and the top-HUD numeric readout are unchanged.

The original ten-slot metal assembly gains recessed enamel, hand-drawn bevels and rivets, steel crossbars, per-owned-deck quiet glints and distinct glowing tide/wave, storm/bolt, salvage/hook and blessing/crystal engravings. Unowned slots and inactive effects stay dark. Active HP/shield gauges add a brief visual impact highlight without changing damage. The effects are vector-rendered in Godot with no borrowed textures and no new runtime image dependencies. Phone/wide close encounters, heading-to-hull separation and save-neutral presentation are covered by tests and captures.

## M3068: heading-stable ship captions (video 207267.mp4)

The M3067 silhouette anchor followed the current animation frame. That made the complete name/ID/HP/shield/deck cluster jump by many pixels when switching the eight starter-ship headings. M3068 caches the largest vertical extent across every source frame for each ship design at the actual displayed length (and across intact/damaged starter art), then anchors the entire cluster at one constant offset below that envelope. Camera travel continues to follow the ship; steering can no longer alter the caption baseline. NPC nameplates continue to resolve close encounters, but only their local collision offsets are eased: their absolute screen coordinates never lag behind the moving hull. No adjustments to actual deck stats, saves or weapon damage. Regression checks explicitly rotate both player and NPC ships and change starter damage state while asserting a fixed caption baseline.

## M3069: movement-stable NPC captions (video 207270.mp4)

The Nov 5 gameplay video shows ship names disconnected from their ships, e.g. Frost-Schwarzbart shifted horizontally and Frost-Eisfregatte pushed below an island. The M3067 avoidance routine chose distant free positions (up to multiple full label widths/heights); M3068 eased those remote offsets but could not prevent detachment. This pass removes the repulsion candidates and NPC interpolation completely. Each actor's name and HP/shield bars are drawn at the stable per-design hull anchor, with precisely zero side or vertical displacement from neighboring ships. Dense crowds may have overlapping text temporarily; the target then the player are drawn last for legibility and all NPC names remain present. No deck mechanics, save format, simulated ship movement, and updater runtime are changed. Tests now check relative anchoring through screen size, camera panning, close ship overlap and target changes, rather than treating non-overlap as a correctness requirement.


## M3070: render ship names, HP/shield and decks in stable screen coordinates

The uploaded 207270.mp4 shows the name, player ID, status bars and deck assembly deforming/shimmering when the camera follows a moving ship. Their old renderer drew into the zoomed/panned Node2D canvas, counter-scaled each plate by 1/camera.zoom, and used an additional font growth factor. The entire caption is now painted instead through a dedicated unscaled CanvasLayer Control. Its world anchor is projected once each frame, snapped to whole screen pixels and painted with exactly one controlled screen scale. No camera transform, zoom inverse, or HUD ui.scale is applied to the glyphs or rectangular gauges. The existing direction-independent hull anchors and the absence of distant NPC caption repulsion remain unchanged. The standalone screen painter keeps all ten real regular deck slots, side fittings, player-only rank, translucent ID and numeric HP restricted to the top HUD. It changes presentation only, not saves, combat or the Android native shell. New tests assert the overlay is a screen-space sibling of the scaled HUD and always covers the viewport size.


## M3071: integrated original deck art and native HUD motion

Nine original 128×128 transparent SVG deck insignia (cannon, armor, hunter, navigation, logistics, tide, storm, salvage and blessing) were committed under assets/ui/abyssal/. The icons are now loaded and used in real mounted-deck rows, deck storage and purchase options, special deck purchase rows, crystal blessing and active-buff chips; neither a mockup nor a decorative-only image. All ten saved physical slots remain authoritative. Existing helm, ship and cannon bitmaps are not replaced. Ship and deck menus redraw their real equipment badge at 15 FPS while open, adding material-specific glints without continuous background timers. Buff chips gain subdued inset accents. All orbs now give a brief click ring; firing/cooling and selected controls receive a restrained active sweep, while idle controls avoid unnecessary redraws. Ammunition selection rows get steel/navy gradients, selected-state highlighting and immediate press feedback. The M3070 screen-space nameplate overlay is deliberately unchanged to protect the prior movement/zoom correction. The save schema and gameplay logic are unchanged. Validation includes SVG asset import and native layout tests.
