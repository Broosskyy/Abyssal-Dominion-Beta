# M164 — No-Code Combat/Guild/UI + Hardcode Audit

M164 continues the master-concept production line with a focused legacy hardcode audit. Existing behavior primitives are reused while content breadth moves into data.

## Runtime/content changes
- Cannon and ammunition cycling now use merged runtime rows/counts instead of fixed fallback-array sizes. This removes a concrete blocker that prevented newly authored ammo/cannons from being selectable without code edits.
- Cannon ammo ID resolution now comes from the selected runtime row. Loadout validation also uses runtime counts.
- Six additional original ammunition profiles and three harpoon-family extensions are defined, plus five cannon evolution presentation stages.
- Eight new item/material definitions expand cannon, talent, citadel and guild progression inputs.

## Guild island
- Added five authorable island module concepts: watch beacon, drydock, supply pier, war room and relic vault.
- Building/tower upgrade curves 1–10 are data-defined with visual-stage breakpoints. Live construction, treasury spend, war and ownership remain server-authoritative.

## Interface/Admin
- Progression center moves to M164 and exposes merged ammunition rows rather than only the old fixed list.
- Added authoring contracts for item families, cannon evolution stages, guild island modules/upgrade curves, icon states, tooltip layers and in-game runtime editor schemas.
- In-game shop/liveops/guild/player-support editors remain permission + server + audit gated for production mutation.

## Safety/authority
No local preview flag grants production authority. Payment, commerce publish, guild treasury/war/ownership, account actions and high-risk commands remain server-side authorization boundaries.
