# M175 Production Report

Status: `M175_DATA_DRIVEN_COMBAT_REWARD_MOBILE_FEEDBACK_VERIFIED`

## Production-lock integration
- Masterkonzept V3.8 remains authoritative and the 2026 production/design lock is now represented by an executable data contract.
- Bottom-left remains camera-only, ship movement remains Tap-to-Sail, the primary attack remains bottom-right and the map center remains gameplay-first.
- Existing seekarte, camera, combat rules, progression and server-authority boundaries were not replaced.

## Runtime feedback
- Damage-number density, merge windows, lifetime and scale now resolve through mobile/desktop presentation profiles.
- Critical hits remain individually prominent; dense repeated hits receive a wider aggregation window on small screens.
- Presentation kinds are prepared for damage, critical, DoT, healing/repair, block and armor feedback without moving damage authority into the client UI.
- Rare, Epic, Legendary and Abyssal loot now resolve distinct labels, durations and VFX presentation tiers from shared data.
- VFX intensity is a device-local option. Reduced Motion and Reduced Flashes now actively scale generic combat VFX duration, expansion and burst count.

## Admin/No-Code
Damage-number, reward-presentation, VFX, notification-family and screen-feedback profiles are registered as presentation-only Draft → Review → Publish → Rollback content. They cannot grant damage, loot, currency or entitlements.

## QA
Run `python tests/m175_feedback_presentation_test.py` plus the existing Python suite. Full Godot/Android visual and performance validation still requires Godot 4.7.2 and target devices.
