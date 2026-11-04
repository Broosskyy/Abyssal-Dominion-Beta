# M138 — Runtime Cleanup + LOD Selection + Placeholder Diversity

- The giant hard-coded `SECTORS` and `GRID_SIZE` world definitions are removed from WorldMapSystem. WorldSectorRegistry is now the only built-in sector source; a coordinate dictionary is generated only as a compatibility mirror.
- Restore-by-stable-ID no longer requires a legacy coordinate.
- VisualQualityResolver selects platform budgets and LOD0/LOD1/LOD2 paths when supplied by the asset manifest/replacement record. Missing LOD files gracefully fall back to the normal placeholder/model path.
- Island count now consumes the Mobile/Web/Desktop budget.
- `island_visual` and `harbor_visual` are supported admin content types. Region/sector targeting can change their visual pools without gameplay code.
- Port gameplay remains in the wrapper. A harbor model is purely visual and replaceable.
- All 50 progression ships now have explicit silhouette-production intent. The sequence deliberately alternates compact, lean, broad, long, heavy, high-stern, low-fast, wide, ornate and relic silhouettes rather than producing fifty near-identical ships.
- These are production/placeholder descriptors, not final art. Final Rodin/Meshy/manual GLBs can replace them slot-by-slot.
