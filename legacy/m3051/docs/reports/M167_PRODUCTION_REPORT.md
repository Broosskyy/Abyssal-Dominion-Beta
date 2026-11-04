# M167 — Master-Concept Continuation, Mobile UX, Interaction QA & Content Binding Depth

M167 follows the master concept and deliberately combines content-system depth with mobile/interface hardening.

## Mobile/interface pass
- Added authorable compact-phone, phone and tablet/desktop UI profiles.
- Progression hub now derives panel margin, touch target size and compact tab labels from the M167 profile.
- Horizontal page scrolling remains disabled; tabs wrap and the close action remains permanently reachable.
- Added interaction contracts for modal menus, purchases/upgrades, equipment selection, crafting, guild mutations, commerce/payment and staff commands.
- Added a device QA matrix for 360×800, 393×873, 412×915 and 800×1280 classes.

## Content/source binding pass
- Formalized item-family source coverage for ammunition, harpoons, consumables, cannon materials, special-deck materials, citadel materials and guild construction resources.
- Added no-code binding contracts for loot, shop, quest, event, admiral and bonus-map sources.
- Crafting stations now have data-defined 1–10 progression/unlock breakpoints.

## Admin/no-code
Added authorable registry types for event/admiral/bonus-map source bindings, crafting-station progression, mobile UI profiles, menu navigation, interaction contracts and QA device profiles.

## Authority guardrails
Payment/entitlements, guild treasury/war/ownership, critical staff commands and production publishing stay server-authoritative, RBAC-gated and auditable. UI/config data cannot bypass those boundaries.

## Legacy audit
M167 preserves existing save keys and class/scene compatibility while moving presentation policy out of hardcoded one-size-fits-all values.
