# M151 — Late Fleet Production Architecture

M151 makes regular classes 51–100 and Prestige P1–P5 addressable without declaring duplicated temporary art complete.

## Delivered

- Fifty unique regular AssetSlot paths in waves W5–W9.
- Five independent Prestige paths, outside regular class numbering.
- Ten regular silhouette families and five Prestige recipes with different hulls, proportions, deck structures, mast/sail layouts, weapon arrangements and special features.
- Godot-native visual-only fallbacks so each slot can be inspected before its authored GLB arrives.
- Runtime integration through `AssetVisualLibrary`, the main progression catalog and ShipCatalog.
- Oblique sea-map QA scene containing ten family representatives and all five Prestige ranks.
- Admin production status and continued use of the canonical data-driven `ship` content type.

## Honesty and replacement contract

Procedural fallbacks are explicitly marked `M151_PROCEDURAL_SILHOUETTE_FALLBACK`, never count as final GLBs and own no collision or gameplay. A final replacement must be an authored, genuinely distinct silhouette. User replacement GLBs keep their authored materials. Hull geometry, weapon sockets, sail/mast animation and Runtime VFX remain separate layers.

## Preserved

Godot 4.7.2 Compatibility, fixed-water X/Z gameplay, real 360-degree ship rotation, mobile oblique sea-map camera, M150 regional visuals, Admin/GM, RBAC/MFA/audit/approval, cannons, ammunition, ships, logos, badges, settings and server-authority boundaries remain intact. Web remains preview-oriented; native desktop/macOS/Android/iOS remain the quality targets.
