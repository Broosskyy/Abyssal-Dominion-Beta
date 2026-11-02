# M60 — HUD Readability + Target/Status Production

M60 continues the production-ready UI layer for the PL1–5 sea-map experience.

## Target hierarchy
Dedicated replaceable target frames now exist for Neutral, Hostile, Elite, Admiral and Monster targets. Runtime selection is based on the existing target metadata; the frame itself never owns relation or combat state.

The target HUD also shows a compact hull bar and, when present, a separate shield bar. Relation text remains code-rendered so color is not the only distinction.

## Core combat icons
New polished, text-free placeholders are available for Attack/Cannon, Repair, Harpoon, Target, Hull, Shield and Ammo. They use the same Navy/Gold/Abyssal visual family and can be replaced through stable UI slots.

## Mobile QA
Five explicit phone/tablet QA presets were added, including common landscape sizes and a portrait fallback. Minimum touch target remains 52dp and safe-area avoidance is part of the acceptance contract.

## Replacement boundary
No image contains gameplay text, counts, cooldowns, target state or server truth. Missing overrides keep the packaged placeholder/fallback active.

No native Godot 4.7.2 runtime/device QA was available in this environment.
