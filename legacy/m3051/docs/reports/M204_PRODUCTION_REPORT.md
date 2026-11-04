# M204 — Inventory / Arsenal Readability Pass

M204 continues the V3.8 visual-master convergence with optimized item/equipment icons and clearer inventory/arsenal presentation.

## Delivered
- 40 additional scalable SVG placeholders for materials, equipment, map fragments/seals and progression/navigation items.
- Arsenal item cards now resolve through the ItemUiIconCatalog instead of raw item IDs, so M203/M204 artwork actually appears at runtime when a slot exists.
- Category badges make ammunition, active items, harpoons, materials, equipment and progression resources easier to scan.
- Powder and plate controls now use their established item icons.
- New M204 inventory-presentation catalog keeps icon/category decisions out of gameplay values.

## Locked behavior
- No damage, reload, cooldown, economy, collision, loot or progression values changed.
- Mobile/Web/Desktop use the same content, icons, world and gameplay. Only UI sizing, touch targets, spacing and safe areas are responsive.
- Seekarte remains the main play space; this pass does not add a permanent bottom menu bar.

## QA
Static source validation only. Native Godot/device visual acceptance remains pending.
