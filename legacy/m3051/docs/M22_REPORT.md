# M22 — Visual Master HUD Convergence II

M22 continues the direct reconstruction toward the user-owned `152969.png` gameplay visual master without replacing the established M20/M21 gameplay systems.

## Implemented
- Larger lower-left helm matching the visual master's visual weight.
- Larger primary fire control and more separated right-side repair/boost/target cluster.
- Larger circular minimap and two adjacent world/group utility controls.
- Top navigation composition now follows Ships / Events / Quests / Shop / Guild / Chat / Achievements / Logbook / Rankings / Bonus / Menu.
- Wider mission panel and larger desktop local-log/chat footprint.
- Bottom ammunition controls spaced and enlarged for touch readability.
- Added safe offline placeholder feedback for visual-master navigation items that do not yet have authoritative systems.
- Shared layout remains the single source for drawing and touch/mouse hit testing.

## Preserved
Combat, targeting, tap-to-sail, pinch zoom, shipyard, arsenal, progression, sector encounters, saves and cross-platform profiles are not reset.

## Validation
Static M22 contract and M5 platform contract pass. Historical milestone tests that assert exact old version strings are not M22 acceptance tests. A fresh Godot 4.7.2 engine render/export is still required for visual acceptance.
