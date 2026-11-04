# M273 Production Report — Authoritative Encounter / Spawn / Respawn / Admiral & Boss Phase Orchestration

Master basis: V3.8. Seafight and Battle of Sea remain clean-room genre/UX references for readable naval encounter cadence, phase telegraphs, waves and boss/admiral presence; no proprietary spawn tables, boss mechanics, layouts, names, assets, values or content are copied.

M273 adds a dedicated server-authoritative encounter lifecycle boundary above M272. Encounter activation, spawn/despawn, respawn/reset, wave/add orchestration, admiral/boss phases, defeat/completion, cleanup and reward-handoff authorization are server-owned. Clients only render confirmed replicas and non-authoritative telegraphs.

M273 does not replace prior authorities: M272 still chooses per-entity AI intent, M271 validates target legality, M268 owns movement, M269/M270 resolve combat, M267 replicates confirmed world state and M266 remains the atomic durable reward/loot/value settlement boundary.

No final population caps, spawn/respawn/reset timings, wave intervals, add counts, boss phase thresholds, phase delays, encounter timeout, cleanup delay, re-entry grace or concurrent encounter budgets are invented. Production encounter scheduler/spawner, persistent encounter repository, authored boss/admiral profiles and native multiplayer/load/adversarial QA remain open.
