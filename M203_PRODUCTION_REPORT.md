# M203 — Combat / Item Icon Production Pass

M203 continues the V3.8 visual-master convergence with a production-oriented vector icon family for ammunition, action items, support payloads and inventory items.

## Delivered
- 8 distinct cannon-ammunition SVG icons.
- 11 action-item SVG icons.
- 12 inventory/material/support SVG icons.
- 6 harpoon/support-ammunition SVG icons.
- Existing runtime visual slots now resolve ammo/action/support icons to M203 artwork.
- `ItemUiIconCatalog` gives inventory/menu surfaces a stable icon-slot resolver for the new item family.

## UI / gameplay rules
- High-contrast silhouettes remain readable at quickslot size.
- Navy/gold framing follows the approved visual-master direction while category accents distinguish effects.
- Mobile/Web/Desktop use the same icons and content. Only responsive UI size, spacing, touch target and safe-area adaptation may differ.
- Assets are replacement-ready placeholders: no damage, cooldown, collision or economy value is stored in artwork.

## QA
Static source validation only. Native Godot/device visual acceptance remains pending.
