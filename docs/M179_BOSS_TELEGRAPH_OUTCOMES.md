# M179 — Boss Telegraph Shapes and Outcomes

M179 extends the M178 locked danger zone into three readable behavior families. Circle attacks test distance from the locked target point, line attacks test distance from the snapshotted boss-to-target segment, and boss rings communicate self-casts without pretending they are dodgeable target attacks.

## Runtime behavior

- Aimed Volley and Piercing Barrage use narrow line lanes.
- Escort Break, Hunter Pulse, Command Mark and Mortar Zone retain circular target zones.
- Guard Call, Armor Shell, Enrage and Last Stand use boss-centered rings.
- The boss origin and target position are snapshotted at cast start for deterministic local prototype resolution.
- Target attacks produce concise `TREFFER` or `AUSGEWICHEN` feedback after resolution.
- Missing/sunk targets, sunk bosses and tree removal clear pending visuals without applying stale effects.
- Authored VFX scenes are additive accents; the gameplay-readable procedural shape remains present and authoritative.

## Production locks

No touch control, HUD anchor, ship movement or camera behavior was changed. Shape visuals remain replaceable presentation layers. Online hit resolution, damage, statuses and rewards remain server-authoritative.
