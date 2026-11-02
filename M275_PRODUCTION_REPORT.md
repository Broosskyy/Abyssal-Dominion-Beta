# M275 Production Report — Authoritative Loot Table / Drop Pool / Group & Fleet Reward Distribution

## Scope
M275 extends V3.8 and M274 with a fail-closed server-owned loot resolution boundary. M274 still determines participation/reward eligibility; M275 selects authored loot/drop pools and resolves personal/group/fleet distribution; M266 remains the only durable ownership/value settlement boundary.

## Implemented
- `M275AuthoritativeLootDistributionRuntime` with server-verified snapshot/event ingestion, environment/encounter binding and revision/sequence/tick stale guards.
- Separate server-owned pool context, resolved drop state, personal distribution, group distribution, fleet distribution and settlement authorizations.
- Fail-closed client permissions: no local pool selection, drop roll, rarity override, reward assignment, group/fleet split, reward-instance creation or settlement authority.
- Data contract for NPC, monster, admiral, boss, event, bonusmap, quest and special-PvE pool contexts.
- Command Deck system-status cards without a new main-menu entry or permanent debug HUD.
- Admin/No-Code policy types for loot tables, drop pools, group/fleet distribution and loot settlement authorization.
- V3.8 convergence entry remains `PARTIAL`; production loot service/repository and native multiplayer/concurrency/dupe QA remain open.

## Genre reference lock
Seafight and Battle of Sea remain clean-room genre/UX references only for naval loot readability and reward feedback. No proprietary reward tables, probabilities, formulas, currencies, names, mechanics, layouts or assets are copied.

## Intentionally unset
Final drop probabilities, rarity weights, quantities, pity/guaranteed-drop rules, personal/shared mix, group/fleet share formulas, round-robin rules, contribution scaling, duplicate protection, caps and reward values remain unset until measured and balanced.

## Production remaining
- authoritative loot-table/drop-pool resolver service and durable authored pool repository
- secure RNG/roll ledger and idempotent resolution receipts
- group/fleet membership snapshot integration at resolution time
- M266 atomic settlement integration for every assigned reward
- live content version pinning/rollback and admin validation for pools
- concurrency, disconnect, reconnect, double-resolution, dupe and adversarial QA
- native Godot/backend multiplayer validation
