# M131 — PL6–50 Admin Overlay, Item Behavior Runtime, Encounter Content IDs, Bonusmap Integrity

- Every PL6–50 progression band now reads an optional verified `rules.progression.levels.<level>` overlay. Existing band JSON is fallback only.
- Common action-item mechanics are routed through the whitelisted Behavior Component executor. Existing specialized effects remain compatible.
- Regional NPC/admiral stable content IDs can resolve admin-authored definitions and override name/stats/AI/asset metadata after runtime modules exist.
- Bonusmap entry now has a local receipt: failed instance creation refunds the entry item, successful instance creation commits it.
- Interrupted active Gold/Abyss maps load as a re-entry credit instead of silently deleting the paid entry.
- Bonusmap router stores/restores both return sector and player position.

This is still local integrity architecture, not a transactional server backend. Production wallet/reward idempotency remains a later server-authoritative requirement.
