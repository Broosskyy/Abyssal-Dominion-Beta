# M274 Production Report — Authoritative Kill Credit / Loot Drop / Reward Eligibility / Encounter Persistence

Master basis: V3.8. Seafight and Battle of Sea remain clean-room genre/UX references for readable naval participation, kill/loot feedback and boss/admiral reward clarity; no proprietary drop tables, contribution formulas, reward values, names, layouts, assets or mechanics are copied.

M274 adds a dedicated fail-closed server-authoritative boundary after M273 encounter completion and M269/M270 combat evidence. Contribution, kill credit, group participation, reward eligibility, loot/reward authorization and reconnect/recovery persistence are server-owned. Clients only render confirmed replicas and cannot restore credit, roll loot, grant rewards or confirm settlement.

M266 remains the sole atomic durable wallet/inventory/ownership/loot/reward settlement boundary. M274 only authorizes handoff; it does not create durable value. TEST/GLOBAL remain strictly isolated.

No final contribution thresholds/weights, group-share formulas, kill-credit tie breakers, drop probabilities/quantities, reward values, disconnect grace, persistence cadence, recovery timeout or anti-farm windows are invented. Production contribution ledger, eligibility repository, drop service, recovery service and native concurrency/dupe/adversarial QA remain open.
