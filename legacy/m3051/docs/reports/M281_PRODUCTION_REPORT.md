# M281 Production Report — Combat HUD Target / Reload / Ammo / Status Visual Convergence & Naval Battle Feedback Polish

Master basis: V3.8. Continues M280 and preserves M267–M280 authority boundaries. Seafight and Battle of Sea are clean-room genre/UX references only.

## Implemented
- `M281CombatHudConvergenceRuntime` as fail-closed presentation layer over server-confirmed M269/M270/M271 snapshots.
- Compact target legality/relationship emphasis, reload/salvo/ammo visual model, prioritized status-effect presentation and boss/admiral telegraph hooks.
- Concrete GameHud/NauticalHud integration plus an active-ammo identity chip attached to the bottom-right combat cluster.
- Sea-chart center, Tap-to-Sail surface, bottom-right primary attack and bottom-left camera joystick remain unobstructed.
- Mobile/Desktop parity foundation and safe-area-aware hierarchy.
- Command Deck status, Admin/No-Code presentation policy definitions and convergence evidence.

## Authority lock
M271 owns target legality/relationships; M269 owns fire/outcome; M270 owns reload/status/projectile state. M281 only renders. Local VFX/animations/ammo labels never authorize target, reload, ammo consumption, damage/heal, status application or boss phase. TEST never transfers to GLOBAL.

## Intentionally unset
Final combat-feedback lifetime, reload-ring animation timing, damage-number density, status-chip limits, boss-telegraph duration and platform spacing scales remain unset until native gameplay measurement.

## Production gaps
Live server event binding, final authored combat HUD assets, native mobile/desktop overlap QA, accessibility/localization and latency/jitter multiplayer visual-convergence QA remain open.
