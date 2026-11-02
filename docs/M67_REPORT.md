# M67 — P0 Island / Harbor Visual Differentiation + Coastline Readiness

M67 follows the master concept's world-production strategy: island bases remain complete GLB bases, while biome decoration, architecture, nature, POIs and VFX stay modular where useful. The master explicitly calls for nature instancing/LOD and Godot-owned foam/fog/dynamic VFX.

Tropical Small, Tropical Medium and Cliff/Cove now have separate fallback presentation profiles so their sea-map silhouettes no longer intentionally converge on the same round form. Cliff/Cove is biased toward an elongated, non-round landmark silhouette. Haven's Reach receives its own profile and a modular architecture contract.

Haven's Reach now has prepared visual slots for Pier, Lighthouse, Shipyard, Market, Arsenal, Quest Hub and Decoration. They are optional visual modules; port services remain code-owned.

M64 texture/material families are mapped to tropical, cliff/cove and harbor visual families. World LOD rules make decorative nature/props disappear before the base island silhouette and preserve coastline readability longer.

This is aligned to the current Asset Production Masterlist P0 island direction. Final islands remain water-free GLBs with modular vegetation/POIs.

No native Godot 4.7.2 parser/runtime/device QA was available in this environment.
