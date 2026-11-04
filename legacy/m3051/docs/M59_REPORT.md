# M59 — Core HUD Visual Production Pass

M59 starts the polished, replaceable interface production layer while keeping all hitboxes and gameplay logic code-owned.

## New centralized visual slots
- combat ring normal / active
- quickslot frame
- target frame
- hull / shield bar frames
- ammunition/item picker panel
- picker row normal / selected

All new placeholders are original, text-free SVG graphics in the dark Navy / Gold / Abyssal visual language. They are intentionally good enough for ongoing playtests but remain replaceable through `visual_overrides.json`.

## Runtime integration
The combat ring, target frame and combat picker now consume the new VisualAssetCatalog slots with procedural fallback. Quickslot frame integration is also prepared in NauticalHud where matching runtime rects are drawn.

## Mobile contract
Minimum touch target remains 52dp. Safe areas, counts, cooldowns and labels are never baked into the image. Graphics cannot change combat behavior.

## QA
The Asset QA Lab adds an `M59 HUD` filter so all new interface assets can be reviewed together.

No native Godot 4.7.2 runtime/device QA was available in this environment.
