# M64 — PL1–5 Texture / Material Production Readiness

M64 prepares the texture/material side of the asset pipeline so final models can arrive without forcing a material-system rewrite.

## Stable texture slots
Eight P0 texture slots now exist for ocean normal, ocean foam, sand, rock, vegetation, harbor wood, harbor stone and coast foam mask. Each includes a packaged original procedural placeholder and a separate override path contract.

WaterSurface now consumes `TextureMaterialCatalog` instead of hard-coding recovered test textures.

## Material families
`EnvironmentMaterialCatalog` provides reusable fallback material families for sand, rock, vegetation, harbor wood and harbor stone. These are visual-only and never own collision or gameplay.

## Import / compression
M64 defines mobile-first texture resolution and compression guidance. 1K is preferred for repeated small props/environment pieces, 2K is reserved for hero/readable surfaces, and unique 4K textures are excluded from the PL1–5 mobile baseline unless profiling later justifies them.

## Region presentation
Tropical, Storm, Ember and Veil presentation profiles define color/lighting direction only. They cannot change combat, stealth, navigation or range.

## Platform metadata
Android/iOS/Desktop export metadata is updated to 0.64.0 / build code 64.

No native Godot 4.7.2 runtime, Android template or device memory profiler was available in this environment at source-build time.
