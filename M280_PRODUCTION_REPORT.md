# M280 Production Report — Reward Presentation Visual Integration / Combat HUD Loot Feedback / Boss Reward Reveal Polish

Master basis: V3.8. Continues M279 without replacing M278 inbox, M277 delivery, M276 roll integrity or M266 atomic settlement.

## Implemented
- `M280RewardVisualIntegrationRuntime` as fail-closed presentation-only visual layer over server-confirmed M279 state.
- Sea-chart-first reward card view model with safe-area-aware compact mobile and wider desktop layout foundation.
- Direct `GameHud` + `NauticalHud` integration for confirmed reward title/detail, stable `icon_asset_id` hook, inbox badge and emphasis.
- Boss/admiral/high-emphasis reveal hierarchy without blocking center gameplay, bottom-right attack or bottom-left camera controls.
- Stable master-item/icon reuse hook; slot/frame treatment remains UI foundation instead of baked icon artwork.
- Presentation-only motion/VFX hook boundary; visuals never prove ownership, claim or settlement.
- Command Deck Online & Systemstatus integration; no reward main menu or permanent debug HUD.
- Admin/No-Code visual layout/reveal/icon/VFX policy definitions and convergence evidence.
- Clean-room Seafight/Battle of Sea genre/UX reference retained.

## Intentionally unset
Final reveal duration, stacking limit, boss motion timing, VFX intensity and platform spacing scales remain unset until native gameplay/UI measurement.

## Production gaps
Authored final reward assets/icon coverage, live M279 event binding, native mobile/desktop overlap QA, accessibility/localization and real multiplayer reward-presentation QA remain open.
