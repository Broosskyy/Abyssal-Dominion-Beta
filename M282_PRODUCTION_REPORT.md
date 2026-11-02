# M282 Production Report — Combat Event Feed / Damage & Heal Number Coalescing / Impact VFX & Hit Confirmation Polish

Master basis: V3.8. Continues M281 and preserves M267–M281 authority boundaries. Seafight and Battle of Sea remain clean-room genre/UX references only.

## Implemented
- `M282CombatEventFeedbackRuntime` as fail-closed presentation layer over server-confirmed M269/M270/M281 state.
- Ordered server feedback events with stable event IDs, revisions/sequences and duplicate/replay rejection.
- Presentation-only coalescing for repetitive standard damage/heal/DoT/HoT per target/type while keeping critical/block/miss salience distinct.
- Concrete GameHud/NauticalHud target-proximate result marker and compact safe-edge combat feed; sea-chart center and locked bottom controls remain free.
- Impact-VFX hook metadata is presentation-only and can never apply damage/heal/status or confirm projectile impact.
- Command Deck status, Admin/No-Code presentation policy types and convergence evidence.

## Authority lock
M269 owns fire/outcome, M270 owns projectile/status temporal truth, M271 owns target legality and M281 owns combat-HUD convergence. M282 only presents already confirmed combat events. Client numbers, VFX, animation, audio or haptics never become combat truth. TEST never transfers to GLOBAL.

## Intentionally unset
Final coalescing window/distance, number lifetime, visible feedback budget, crit emphasis duration, impact VFX intensity, hit-stop/screen-shake strength and platform feedback density remain unset until native measurement.

## Production gaps
Live server event-stream binding, authored impact VFX/audio/haptics, native mobile/desktop density and overlap QA, accessibility/localization and latency/jitter/order/replay multiplayer QA remain open.
