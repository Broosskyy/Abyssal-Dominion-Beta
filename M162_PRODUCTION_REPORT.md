# M162 — Gameplay Depth + No-Code Authoring Pass

M162 turns the M160/M161 definitions into persistent local gameplay-preview systems while preserving production authority boundaries.

## Gameplay integration
- Normal ship decks remain 1–10 and visually layered under the hull through the existing M159 ship-extension visual path.
- Six special-deck families now have persistent ownership/upgrade state (levels 0–5), per-ship equip state, data-defined costs, effects and VFX profile references.
- Five talent trees now contain 60 explicit nodes with prerequisites, ranks and data-defined effects. Talent points are awarded on pirate level-up in local gameplay.
- Six citadel branches now have persistent 0–10 progression with data-defined cost curves and effects.
- Four cannon mastery tracks (barrel, carriage, chamber, runes) now have persistent 0–10 state. Damage/reload modifiers are applied in the existing weapon runtime rather than a parallel combat system.
- Added initial new harpoon/consumable/guild-material definitions and inventory slots for continued content production.
- M162 progression center connects these systems to a mobile-scrollable UI instead of leaving them as catalog-only rows.

## Guild direction
Guild island remains server-authoritative for treasury, ownership and war. M162 formalizes 10-level building/tower progression, guild rank/permission content types, siege-rule authoring, and the cannon/chain/mortar/ward tower-role set.

## No-code authoring
Added authorable content types for interface panels/actions, tooltip and animation profiles, economy formulas, upgrade trees/nodes, guild ranks/permission sets/siege rules, consumable effects and harpoon profiles. Existing Draft → Validate → Preview → Review → Approve → Schedule → Publish → Disable → Rollback remains the production pipeline.

Code remains required only for genuinely new engine/behavior primitives, network protocols, security-boundary changes and payment-provider adapters.

## Authority
Paid entitlements, production shop mutations, guild ownership/treasury/war, account actions and critical GM commands remain server-authorized. Local development UI never grants production authority.
