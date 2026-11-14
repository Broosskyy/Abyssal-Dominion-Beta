# Classic Seafight-style Click-to-Tile and Online Course — Update 345

Status: merged from PR #59 after Godot 4.7.2 browser test 144 and Python server integration tests. Visual feel remains subject to real-device comparison.

## Sources and limitations
- Seafight 2011 movement was described as 4-view "tänzeln".
- Seafight Offline Reloaded (war-sloop, 2013) discussed a 48×32 isometric grid adapted for A* pathfinding.
- The open-source Sea Bandits reconstruction (MatiasMunk/seabandits-src) anchors odd/even rows at x=(r%2 ? 0 : 24)+48*c, y=16*(r+1), and uses tile-to-tile interpolation. This is reference evidence, NOT original commercial Seafight source.

## Actual course model
- World coordinates use one globally anchored staggered isometric grid. Neighbour centers differ by (±24,±16), not arbitrary 32-unit screen steps.
- Sea clicks and minimap water coordinates select a specific walkable tile centre BEFORE A* course planning. Harbor, portals and scripted targets retain exact absolute coordinates.
- The precomputed 4-neighbor itinerary is followed as physical movement in Classic 2D. The four existing baked ship-view sprites match the active itinerary segment. Both 30Hz simulation and interpolation use the same micro-step trace; no independent picture oscillator.
- Destination is the selected tile centre, so there is no unnecessary final off-raster leg. New taps discard the old pending micro-route.
- Classic route preview shows the actual selected destination marker; a misleading straight dashed path line is not displayed.

## Online and crossplay
- Connected clients are normally controlled by a separate presence server; prior direct-only server movement bypassed Classic's local 48×32 raster.
- Classic clients now send up to 512 preexpanded collision-checked micro-waypoints and a compatible navigation hint. Existing protocol-2 servers ignore the hint but still sail those points, giving other clients the shared physical route.
- Updated Python server also accepts the new hint and normalizes travel pace for raster length; if no preexpanded route is available for a long course, it can reconstruct the same grid route from the high-level waypoints.
- Native 2.5D/3D clients still send normal direct course commands. Network world positions remain shared; no additional standalone app.
- The public server must deploy the updated code separately before optional authoritative pace normalization takes effect. Older servers still accept typical preexpanded raster courses.
- Gameplay authority, combat and island collision on the presence server remain prototype-only and are not final MMO backend capabilities.

## Camera presentation
- Classic desired zoom 1.12, without forced 0.78 zoom on compact phone HUD.
- Classic hull scale desktop 0.45, touchscreen 0.60 (including mobile browser, not solely native APK). Classic touch camera factor 0.94.
- Manual zoom range 0.65–1.8. Physical hitboxes, combat range, saves, 2.5D/3D model geometry are unchanged.

## Tests
- GitHub Actions browser preview #144 on development branch checked the actual Godot GLB sprite bake, Classic tiling, navigation, zoom/UI, WebGL startup and mobile shell.
- Python unittest suite verifies 48×32 server tile routes, preexpanded-route compatibility, two connected client snapshots, and unchanged direct native mode.
- Automated regressions cannot establish an exact subjective match to historical Seafight. Test tap-right and mid-route tap-upper-left with camera panning and online/guest sessions separately.
