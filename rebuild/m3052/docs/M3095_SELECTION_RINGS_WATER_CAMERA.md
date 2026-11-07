# M3095 · Vessel selection rings, 3D camera and water contact

## Goal
Classic Seafight / Battle-of-Sea-style underwater circles that make player identity and tap selection obvious while preserving the real, freely turning GLB models.

## Implemented
- **Player**: a restrained cyan double-line elliptical water-level ring that is always visible around the player's vessel in classic, hybrid and 3D. Moving illuminated arc segments; never an opaque disk.
- **Selected enemy / neutral**: only a living, currently selected NPC gains its own wider elliptical double ring. Enemy red-orange, neutral golden. The four slim tactical ticks and slow animated accents distinguish it from the player.
- **Towers**: use the same target indicator (different radius), while keeping their separate range overlay.
- **Selection logic**: the circle derives directly from the existing authoritative `sim.target`; tap, target-cycling and death are handled immediately. The ship's identity, selection and attacks remain unchanged.
- **Camera**: 3D and Hybrid now share a consistent 40° elevation setting, avoiding a silhouette jump when changing modes.
- **Sea contact**: the new gameplay PBR and Shaded GLBs are lowered slightly to a 23% height-immersion reference (from 20.5%). The original imported meshes are unchanged; all movement, physics and water are still 2D. The subtle 2D waterline remains and the hull's underwater shadow is marginally stronger.
- **Caption**: the new GLBs get 7.5 px baseline clearance instead of 9 px. The label stays heading-invariant and attached to the existing HP/shield/deck display.
- **Safety**: no new textures, no new or modified GLBs, no save migration, no gameplay stat changes. All versions of the game use the same ring function, including classic fallback.

## On-device acceptance
Use black-green test ship, compare B PBR and C Shaded at the same zoom. Sail 360° and confirm: cyan ring follows captain and never rotates with the hull; gold/orange ring appears immediately when an NPC is tapped or cycled, disappears on sinking and doesn't appear around other ships; keel sits closer to the 2D ocean; names stay under hull; no extra thick floating aura.

This is not a 3D water shader. It improves 2D sea contact and readable selection on the current hybrid renderer.
