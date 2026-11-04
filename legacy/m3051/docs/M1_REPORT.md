# M1 — Asset truth and visual foundation

## Result

M1 upgrades the isolated Godot reconstruction from a functional greybox into a modular visual foundation derived from the supplied build's structure. It does not reuse original credentials, original source code or distributable third-party asset bytes.

## Asset source-of-truth catalog

The supplied Unity data was indexed into 14,932 technical records:

| Type | Indexed records |
| --- | ---: |
| Gameplay-relevant GameObjects | 8,466 |
| MonoScripts, all assemblies | 2,593 |
| Textures | 1,559 |
| Sprites | 871 |
| Materials | 740 |
| Meshes | 660 |
| Animation clips | 35 |
| Audio clips | 8 |

The catalog includes source asset file, path ID, name, dimensions, texture format, mesh vertex/submesh metadata, animation sample rates and assembly/class mapping where available.

## Implemented visual architecture

- Animated lightweight ocean shader for GL Compatibility
- Modular ship hierarchy with `Visual`, `Sockets`, `Anchors`, collision and audio roots
- Three cannon sockets per broadside
- Nameplate and selection anchors
- Dynamic wake strips driven by ship speed
- Muzzle flash, cannon trail and impact effects
- Tropical, desert and snow island palettes
- Islands separated into `Coast`, `Ground`, `Underside`, props and collision
- Player/enemy selection rings
- Camera zoom and heading-aware look target
- Nameplate edge protection and fixed screen-space separation from ship visuals

## Platform boundary

All visual systems use Godot-native nodes, materials and shaders compatible with the shared Web/Android/iOS/Desktop codebase. Mobile Web remains the performance baseline. Reference-only assets remain excluded from all six export presets.

## Remaining visual work

Licensed GLB ships and islands can replace the procedural visuals without changing gameplay nodes. Additional refinement covers authored LODs, texture compression, shoreline foam, cannon smoke particles, sinking debris, port scenes and device-tier quality rules.
