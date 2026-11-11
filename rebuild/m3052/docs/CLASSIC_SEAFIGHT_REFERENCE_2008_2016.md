# Abyssal Dominion — Classic Seafight 2008–2014/16 reference pass

**Baseline:** Browser Test 34 / signed game-data update 329 (2026-11-11). This document separates verified historical evidence from proposed implementation and pending visual review. It is not a claim of completed frame-by-frame analysis.

## User-selected video references (visual review still pending)

1. https://youtu.be/oDPsBMtFbdc
2. https://youtu.be/TU1vfdJyGWM
3. https://youtu.be/anvSZmTncG4
4. https://youtu.be/P_z28R5JL9M
5. https://youtu.be/PRry_iZN0S8

The linked YouTube playback/transcript could not be accessed from this session, so **none** of their individual scenes, headings, UI widgets or timings has been asserted as an observed fact. A frame-by-frame acceptance comparison requires playable media or user-supplied captures. Avoid guessing what happens at particular timestamps.

## Verified Classic 4-heading movement correction (2026-11-11)

The user's own 12-second screen recording `208796.mp4` exposes large V-shaped course deviations and long detour segments in the previous implementation (up to 144 world units). The linked YouTube ID `oDPsBMtFbdc` was not directly playable here; no timestamps from that video are claimed as inspected.

An independent 2011 GameStar review explicitly describes Seafight ships not sailing directly to a clicked point but "dancing" along it, with four discrete headings that differ by 90 degrees:
https://www.gamestar.de/artikel/seafight-browserspiel-oldie-unter-piratenflagge%2C2321007.html

**Correction after direct comparison of user's current gameplay and historical example (208809.mp4 versus 208797.mp4):** The four visible Classic 2D facings are **presentation only**, NOT an instruction to move the physical actor on 45-degree diagonals. The previous implementation produced giant and then smaller synthetic zigzags because it modified simulation waypoints to match the limited artwork. That was fundamentally wrong. All modes now share the exact same direct, obstacle-avoiding tap-to-sail physics and waypoint list. Only Classic 2D selects four NE/NW/SW/SE sprite frames from the existing eight baked headings. **Additional correction from the user's explicit 'links / rechts' clarification:** While heading west/east (or north/south), the old screenshot pair shows two adjacent 45-degree hull facings *alternating repeatedly during straight travel*, not one fixed facing. The renderer now cycles the two nearby views as a distance-driven left/right pendulum while keeping the actual world course perfectly straight. Exact diagonal travel holds a single appropriate view. The pose freezes when standing still. It does not change course waypoints, ship world coordinates, hitboxes, collision, server sync or camera follow. Other frames remain available for future modern 8-view settings. Entering or leaving Classic never replans or broadcasts a new course merely because of a graphics switch. The chart draws only the actual real course. Camera follow stays locked to the real interpolated ship position. User confirmation of subjective fidelity to old Seafight gameplay is still pending.

The actual per-frame cadence remains subject to comparison against playable historical footage; do not label it a frame-exact match to a video that was inaccessible.

## Period-grounded sources

- German official 2013 sea-chart options: https://board-de.seafight.com/threads/die-seekarte-die-optionen.855/
- German official 2013 action toolbar: https://board-de.seafight.com/threads/die-seekarte-die-menueleisten.857/
- English official 2013 toolbars: https://board-en.seafight.com/threads/sea-chart-toolbars.1042/
- English official 2013 keyboard/graphics options: https://board-en.seafight.com/threads/options-overview.1858/
- Contemporary overview of simple four-direction movement: https://spiele.woxikon.de/browsergames/seafight
- Official 2014 pumpkin event: https://board-en.seafight.com/threads/the-pumpkin-festival-2014.53687/

Historical behavior, not an obligation to reuse trademarks, art, textures or exact layouts:
- A mouse click sets course; the chart can be panned independently and recentered on the ship.
- Graphical ship presentation uses few discrete headings; the 2010-era image should be readable at small scale.
- A fixed combat action strip coexists with user-configurable item slots.
- Dedicated attack/cancel, cannonball, harpoon, action item, bonus map and repair controls.
- Options cover configuring toolbars, keyboard shortcuts, map-scrolling behavior, visual quality and animation toggles.
- An accessible minimap, coordinates and target indicators accompany the ship rather than covering the sea.
- Harbor and equipment upgrades have deliberate, discoverable categories rather than a full-screen HUD permanently obscuring the ocean.

## Implementation trace / order

| Priority | Area | Existing baseline | Acceptance for a close classic feel |
| --- | --- | --- | --- |
| P0 | Sailing | Update 329 real alternating diagonal segments; common simulation | Compare headings and visual leg length to supplied video frames; immediate new course replaces old; no turning arc; no snapping of labels, wake or ring; avoid absurd long zigzags or drift |
| P0 | 2D browser ships | 23 baked GLB-derived atlases and 2D monster motion | Every hull retains identity, matched waterline, anchored shadow, four/eight readable headings and correct selection ring; no full 3D mesh load at browser startup |
| P0 | Combat | One-tap select, fire toggle, ammo menu, existing salvo FX | Single tap = select, explicit fire; optional double tap = fire; immediate stop/cancel; clustered cannonballs and impact FX with readable volley damage; no stat changes from FX settings |
| P1 | HUD | Compact header, ship plates, minimap, quick item slots | Sea occupies most screen; target/HP/shield and 10 decks legible; fixed combat actions distinct from configurable items; portrait and landscape mobile without overlap |
| P1 | Chart navigation | Previous tap-to-sail, camera pad and recenter | **This branch:** arrows pan view, C follows ship, K courses to inspected center, A opens ammo, M menu, shortcuts never fire behind forms; tested independently of ship/cannon systems |
| P1 | Menus | Separate docks, market, yard, decks, castles, quests, settings | Consistent back navigation, tabs, large media/cards where useful, short route to every core action; no copying of original art or UI skin |
| P1 | World | 40 connected seas with whole-edge crossings | Clearly legible map coordinates, island/harbor silhouettes, crossing borders, more distinctive region layouts without giant portal decorations |
| P1 | Graphics performance | Web Classic 2D with 60 FPS cap, signed data | Measure cold and repeat downloads, GPU/CPU frame pacing, touch-to-response latency and memory across actual Android/Web devices; budget imagery and avoid claiming 60 FPS without field measurements |
| P2 | Economy/content | Shipyard/market, guild islands, events, bonus charts | Clear equipment and progression loops, historically inspired event cadence, own currencies/balance/graphics; no fake public-server groups or auctions |
| P2 | Social/crossplay | local player progress and 2-client protocol tests | Verify real accounts and multiplayer only after authenticated public server is deployed; no simulated online claims |

## Mandatory UI split: mobile first, desktop separately

This requirement supersedes any attempt to shrink an old desktop Seafight UI onto a phone. The **game rules are shared** (same saved three configurable quickbar pages, same weapons, cooldowns and actions); only input ergonomics and layout differ.

**Mobile / tablet / small viewport:**
- Large primary fire/stop button at the bottom right, with one-tap ammo, repair and consumable selection within thumb reach.
- Three configurable quick slots on the adjacent right combat rail; quickbar page tabs have a minimum 44 logical pixels of height before HUD scaling, including narrow landscape viewports.
- Camera pad or touch-drag on the left; direct tap-to-sail and tap-to-select remain the principal interaction. No keyboard use required.
- Menus use one-column direct actions on narrow screens, scroll and clear back/close controls; do not hide controls behind permanent wide panels.
- Keep the center of the sea free of toolbars and avoid overlaps at 844×390, 720×405 and high-DPI Android landscape.

**Desktop / mouse and keyboard:**
- Separate configurable quickbar rail at bottom left, not copied from the phone's combat ring.
- Main combat remains on the right; mouse click, right-drag and wheel continue to control navigation.
- Z / X / V activate the three saved quick slots, Q changes quickbar page; arrow keys pan chart, C recenters, K sets a course to the inspected center, M opens main menu, A selects ammunition.
- Shortcut actions never fire while a menu or text field has focus. Disabled supplies (cooldown, out of stock or docked) cannot be activated by hotkey.
- Touchscreen laptops and narrow desktop windows use the responsive touch layout. Desktop keyboard shortcuts remain limited to the desktop input profile.

**Current implementation patch**: `quick_bar.gd` and `sea_map.gd` have separate geometry paths; `classic_navigation_test.gd` covers layout selection, page-button height, screen placement, shortcuts and modal blocking. This is still branch-only code until Godot CI and actual phone/browser captures pass.

## Test checklist for next release

1. Same account/course on browser and Android Classic; positional simulation/path and combat outcomes identical.
2. Pan chart without moving player; K sets a valid course to the inspected map center; C recenters and follows; shortcuts ignored while entering a name or a menu is open.
3. Tap sea, select NPC, fire, change ammo, cancel target and repair with both touchscreen and mouse.
4. Twenty close-range heading flips, zero waterline/label detachment or image inversion.
5. 360-degree eight-view inspection for 11 original models and 10 elite variants; draw one ship from one complete transparent atlas, no off-center icon gaps.
6. HUD/click targets at 1280×720, 844×390, 2340×1080 and 3840×2160; no lost quickbar or covered close button.
7. Cold browser download, second visit cache, FPS/long frame times, input responsiveness and memory logged from real devices.
8. Native renderer switching Classic → Hybrid → 3D → Classic does not create duplicate meshes or alter the guest captain save.

## Non-goals and safeguards

No original Seafight logo, proprietary ship pixels, copied icon assets, pixel-identical menu artwork, or identical protected text; mechanics and general period look are adapted using original Abyssal assets. No silent new economy rules, gameplay damage alterations, server deployment or Android shell version bump in this navigation patch. The standalone QA script must pass before merging. CI on the feature branch is not equivalent to a published signed data release.
