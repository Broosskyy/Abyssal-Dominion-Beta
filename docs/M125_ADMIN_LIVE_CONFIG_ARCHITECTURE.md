# M125 — Admin-controlled balance/economy foundation

Goal: all tunable gameplay/economy values are data/config, not code deployments.

Admin domains: ships/HP/stats, NPC/elite/admiral/monster stats, cannons, ammunition, harpoons/support, items, harbor/item shop, currencies, loot/drop rates, XP/rewards/progression, repair/crafting/upgrades, event/LiveOps, and monetization product presentation.

Authority boundary:
- Local JSON is a safe development/offline fallback.
- Production active config is intended to be versioned, validated, scheduled, audited and rollback-capable from the web/admin platform.
- Real-money prices/provider product IDs must reconcile with payment provider/server.
- Receipts, premium currency and entitlements are server-authoritative. Client/admin presentation never grants ownership.
- No payment secrets in client config.

M125 migrates the first high-value consumers (ship profiles/scaling, cannon/ammo catalog, harbor offers/repair values, NPC override hook). Remaining hard-coded tunables are tracked for subsequent migration rather than falsely claiming 100% completion.
