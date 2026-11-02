# M242 — Officer Progression & Acquisition Readiness

Master basis: V3.8 §§221 and the Sustain/Support Officer contracts.

M242 extends M241 without inventing the balance values that V3.8 explicitly leaves to Combat/Economy playtests. Officer quality, level, XP, traits and acquisition are represented, but live ownership, XP/level advancement, purchases and rewards remain server-authoritative.

## Runtime
`M242OfficerProgressionRuntime` accepts monotonic authoritative snapshots for per-officer level/XP/next-threshold/upgrade state and acquisition publication. Older revisions cannot replace newer state. Without a server snapshot the UI labels the existing roster values as `LOCAL_PREVIEW` and does not infer a next XP threshold.

## Roles
The canonical role vocabulary is Master Gunner, Harpoon Master, Navigator, Shipwright, Quartermaster and Surgeon. M242 records their build specialties but deliberately adds no unvalidated damage, reload, movement, economy or healing percentages. Shipwright remains the already active Repair Master path from M240/M241.

## Respec / loadout
Changing an officer slot is a loadout operation. It never deletes ownership, XP or level. The M241 uniqueness rule remains: an officer cannot occupy two slots simultaneously.

## Acquisition
Core roles remain planably earnable and cannot become mandatory gacha-only progression. Exact costs, XP curves, rarity rates and live entitlement mutation require future authoritative services and balance data.
