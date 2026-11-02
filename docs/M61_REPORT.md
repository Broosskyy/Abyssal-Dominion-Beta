# M61 — PL1–5 HUD Completion + World Readability

M61 completes another visible production layer for the early sea-map slice.

## Combat icon families
Eight cannon-ammunition icons now have dedicated stable production slots:
Iron, Explosive, Chain, Piercing, Ember, Venom, Shatter and Spectral.

Harpoon payloads and support shells also receive dedicated slots, as do all current action items plus Powder and Plates. The HUD picker, detail card and quickbar now resolve these stable M61 slots instead of depending on the older M42 placeholder naming.

## World readability
Replaceable nameplate frames now distinguish friendly/player, neutral, hostile, elite, admiral and monster units. The runtime relation/rank remains code-owned; the graphic only visualizes it.

## Mobile production rule
All new SVGs are original text-free placeholders. Labels, amounts, cooldowns, health state and relation truth remain rendered from runtime data. Final artwork can therefore replace every slot without changing interaction or combat code.

## QA
The Asset QA Lab adds `M61 COMBAT/WORLD` to review the entire new family in one place.

No native Godot 4.7.2 runtime/device QA was available in this environment.
