# M272 Production Report — Authoritative NPC / Monster AI Combat Brain & Threat Resolution

Master basis: V3.8. Seafight and Battle of Sea remain clean-room genre/UX references for readable naval encounter cadence, enemy roles and combat telegraphs; no proprietary AI rules, assets, layouts, names, values or content are copied.

M272 adds a dedicated server-authoritative AI combat-brain boundary on top of M271 target/relationship legality. NPCs, monsters, admirals and bosses share one authority-safe state-machine foundation across IDLE/PATROL/ACQUIRE/PURSUE/ATTACK/REPOSITION/EVADE/LEASH/RETURN/DISABLED/DEFEATED while allowing data-driven archetype profiles later. Threat resolution, target choice, path/attack intent, leash/return and boss-phase decisions remain server-owned. Clients only render confirmed replicas, interpolate confirmed movement and show readable telegraphs.

M272 does not replace M268-M271: M272 chooses AI intent; M268 remains movement authority, M271 relationship/target legality, M269 fire/outcome authority, M270 temporal combat-state authority, M267 world replication and M266 durable settlement.

No final aggro radii, threat weights/decay, target-switch hysteresis, patrol/repath timings, standoff/reposition distances, leash tolerances, phase thresholds or AI decision tick rates are invented. Production AI simulation, navigation/pathfinding, encounter orchestration and native multiplayer/load/adversarial QA remain open.
