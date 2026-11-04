# M166 — Production Depth, Source Graph, Effect Runtime & No-Code Authoring

M166 continues the M159–M165 system-depth line and removes another runtime hardcode island instead of only adding more content rows.

## Combat effect runtime
- Ammunition/harpoon status effects are now resolved by data category instead of a fixed four-effect allowlist in `ShipHealth`.
- DOT effects are iterated generically; defense debuffs and vulnerability/hunter/siege marks are aggregated by category.
- `chill` uses the existing speed-effect primitive and `reload_disrupt` now affects the target's next reload window.
- M166 defines 16 reusable original effect primitives. New content using these primitives does not require a new one-off projectile branch.

## Crafting and source graph
- Added 12 additional recipes on top of the M165 recipes for ammunition, harpoons and consumables.
- Added an authorable content-source graph linking items to crafting, loot, bonusmaps, events, admirals, quests, shops and guild sources.
- The progression hub now shows combined M165+M166 recipes and origin hints from the source graph.

## Presentation
- Cannon mastery remains a four-track 1–10 system with visible breakpoints 1/3/5/7/10 and replaceable badge/model/VFX slots.
- Guild island presentation contracts now formalize level stages, damage states and ownership states while keeping live mutations server-authoritative.

## Admin / no-code
New registry types include source graphs, station requirements, effect primitives, cannon mastery presentation, guild visual stages, and loot/shop/quest source bindings.
Draft → validate → review → publish → rollback remains the production workflow. Paid entitlements, grants, guild treasury mutations, siege changes and production publish remain server-authoritative.

## Legacy audit
- Removed the old `burn/venom/armor_break/spectral_mark` hardcoded effect allowlist from `ShipHealth`.
- M165 crafting API is retained for compatibility but now resolves M166 recipes first and falls back to M165.
- Existing save keys are unchanged.
