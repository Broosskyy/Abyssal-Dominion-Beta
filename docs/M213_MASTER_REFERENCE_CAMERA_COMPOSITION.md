# M213 — Master-reference camera & gameplay composition

M213 recalibrates the runtime camera toward the five approved gameplay master references. The target is a higher, wider oblique top-down sea-chart view: several ships, islands, loot/POIs and a large harbor landmark can be read in one frame. The player ship remains readable but must not dominate the screen.

## Locked composition
- Sea chart remains the primary visual surface.
- Perspective camera, not a flat orthographic map.
- Large harbor/fortress islands act as strong world anchors.
- Multiple encounter actors may be visible simultaneously.
- Minimap stays upper-right; combat cluster and primary attack stay lower-right.
- Camera control stays lower-left and never moves the ship. Ship movement remains Tap-to-Sail / Click-to-Sail.
- No persistent bottom map/menu bar and no centered primary attack.
- Mobile/Web/Desktop share the same world, camera intent and visible gameplay hierarchy; only responsive UI sizing/spacing/touch targets/safe areas differ.

## Runtime calibration
Camera base offset: `(16.8, 29.0, -25.2)`, FOV `40°`, zoom range `0.82–1.62`, pan limit `32`. These are source calibration values and require native Godot/device visual QA against the approved references before being treated as final.

No damage, weapon range, collision, navigation, spawn or progression values were changed by M213.
