# M196 Production Report — Regional World Identity

M196 turns the 360×360 named sea charts from one repeated macro template into deterministic regional compositions while preserving the M194 cross-platform parity lock.

## Implemented

- Added region-aware macro transforms for all canonical regions from Shattered Shores through Iron Maw Reach.
- Locked the island composition to eight gameplay island slots on every platform; removed the remaining seed-dependent seventh/eighth-island variation.
- Added regional route identities such as open coastal crossings, wreck arcs, storm chokepoints, rift rings, ruin archipelagos and high-level gauntlets.
- Added region-aware POI mixes and positions using the existing POI interaction contract; this changes regional character without creating a second reward authority.
- Preserved 360×360 chart size, named map hierarchy, Tap-to-Sail, island blocking/avoidance and non-blocking ships/NPCs/monsters/bosses.
- Mobile/Desktop/Web remain gameplay-identical. Only responsive UI and non-authoritative visual quality may differ.

## Asset status

This milestone is composition/system work. Existing procedural island, wreck, shrine, monster-area and navigation visuals remain replaceable production placeholders where a final AssetVisualLibrary slot is not available.

## Verification

Static regression and JSON validation are required for packaging. Native Godot render/navigation/device QA remains outstanding because the Godot runtime is not installed in this build environment.
