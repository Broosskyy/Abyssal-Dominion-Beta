# M195 — Regional Chart Composition

M195 turns the 360×360 prototype sea into a more deliberate macro composition without changing gameplay parity between platforms.

## Locks
- Mobile/Web/Desktop receive the exact same chart content and deterministic placement.
- Player-facing maps remain region + named chart, never `1/1`, `2/1` style labels.
- Islands remain hard navigation obstacles; ships/NPCs/monsters/players remain non-blocking units.
- Tap-to-Sail, collision authority, combat ranges, rewards and progression are unchanged.

## Composition work
- Eight deterministic macro island anchors spread landmarks around the full chart.
- Seeded jitter prevents charts from looking copied while retaining clear central/diagonal sailing corridors.
- POIs no longer spawn inside the old +/-27 prototype patch; they now occupy the full playable chart with larger separation and center clearance.
- The result is intended to provide recognizable routes, flank passages and exploration arcs before final authored islands/POIs replace procedural slots.

This is static source verification. Native Godot/mobile/desktop visual and steering QA remains required.
