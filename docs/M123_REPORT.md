# M123 — PL1–45 Integration, Runtime Optimization & Trial Gameplay

M123 deliberately does not unlock PL46. It hardens the existing client first.

- SectorGraph provides stable level/neighbor lookup and a migration path away from ever-growing rectangular scans.
- Central mobile_low/mobile_high/desktop runtime budgets implement the V3.7 LOD/mobile direction.
- Encounter spawning now respects device-aware NPC caps while bosses keep a small exception budget.
- PL40 and PL45 trials gain staged gameplay runtime instead of being only readiness + harbor claims.
- Trial state persists in the existing Voyage save contract.
- M121/M122 progression save fixes remain intact.
- PL46–50 Abyssal Dominion final-band slots are preproduced only, not unlocked.
- Asset QA contracts explicitly require Hero LOD0/1/2, top-down readability, reduced mobile VFX and stable sockets/fallbacks.
