# M63 — Early World Visual Polish + Environment Production

M63 is an explicit optimization/polish milestone rather than only a feature-add milestone.

## Water and coast
The compatibility-safe water shader has been tuned for cleaner macro variation, subtler crest foam, lower metallic response and improved oblique-camera readability. Water subdivision counts are now driven by the centralized mobile visual budget. Reduced-motion remains supported.

Shoreline foam is subtler, quality-tier aware and reduced-motion aware. Wake opacity is reduced, a separate bow-foam fallback is added, and water splash presentation is toned for mobile readability.

## Replaceable environment/VFX slots
Stable prepared slots now exist for ship wake, bow foam, shoreline foam, shallow-water edge, water impact, hull impact, safe-zone ring and safe-zone beacon. Missing overrides preserve procedural fallbacks.

## Haven's Reach
The safe-zone ring is visually toned down and receives an optional replaceable scene hook. A lightweight procedural safe-zone beacon is added as fallback and can also be replaced through a dedicated slot.

## Performance
M63 adds low/balanced/high budgets for water subdivisions, shoreline complexity and transient visual effects. Combat VFX now respects a visual-only transient budget. These limits never alter combat results or hit logic.

## QA
Environment QA explicitly checks ship silhouette, world labels over water, shoreline readability, safe-zone dominance, phone readability and low-quality information preservation.

No native Godot 4.7.2 runtime/device profiler QA was available in this environment.
