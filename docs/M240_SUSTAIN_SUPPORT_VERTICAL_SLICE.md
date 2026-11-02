# M240 — Sustain & Support Vertical Slice

M240 converges the V3.8 Repair, Shield, Support & Ship Supplies Bible into the reconstructed runtime without pretending final balance or live server authority exists.

## Implemented runtime contract
- Hull and shield remain separate pools. Hull repair does not restore shield; shield recovery does not repair hull.
- The sea-chart Repair HUD action now toggles normal hull repair through `M240SustainSupportRuntime`; it no longer consumes an emergency repair item in the canonical player factory.
- Repair Master I–III and Shield Master I–III have explicit prototype definitions. Their numeric rates/delays are provisional and must be tuned after TTK/PvP playtests.
- Shield recovery observes a post-damage delay and is independent from normal hull repair.
- Emergency repair items remain inventory/action items and are not conflated with the normal repair button.
- Healing cannon mode supports explicit friendly/self target cycling, range, reload and ammo checks.
- Hull, shield and hybrid support ammunition are data-driven in `support_payloads.json`.
- Support contribution records effective restoration only; overheal is naturally excluded because ShipHealth returns the actually applied amount.
- Black Powder and Armor Plates keep their existing qualified-consumption contracts.

## Authority boundary
Local runtime is a prototype gameplay implementation. Competitive support contribution, rewards, anti-abuse, PvP healing modifiers and final balance remain server/config authoritative for live operation.

## Interaction notes
The existing `target` HUD control cycles friendly/self targets while support mode is active and keeps hostile target/harbor behavior outside support mode. This avoids adding another permanent combat button.
