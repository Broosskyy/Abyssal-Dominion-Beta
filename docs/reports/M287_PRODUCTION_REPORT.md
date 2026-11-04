# M287 Production Report

## Scope
Ship Motion Identity / Bow Displacement / Stern Wake / Turn Water / Hull Waterline / Anchor Ripple / Sail Response / Replaceable Motion Placeholder Rig.

## Implemented
- `M287ShipMotionIdentityRuntime` as a fail-closed motion-presentation replica over M268 authoritative movement.
- Revision-, tick-, sequence-, event-ID- and presentation-seed guards for motion snapshots and events.
- Eight replicated presentation states: ANCHORED, IDLE, ACCELERATING, CRUISE, TURNING, BRAKING, DRIFTING and CORRECTING.
- Five data-driven motion identities: LIGHT, BALANCED, HEAVY, ADMIRAL and ABYSSAL.
- `M287ShipMotionVisualRig` attached to every procedurally generated ship.
- Six stable motion sockets and six replaceable water/sail asset slots.
- Runtime-composed paired bow displacement, dual stern wakes, directional turn curls, hull waterline, anchor ripple and a socketed sail-flow overlay without direct sail-mesh access.
- Existing local `ShipWake` retained as compatibility fallback and hidden when the M287 rig is ready.
- Local-development preview reads `ShipMotor` only while `server_authority_verified=false`; online rendering accepts only confirmed M287 state/events.
- Mobile/Web keeps the same motion profile and gameplay truth while reducing secondary turn-water visibility.
- GameHud/NauticalHud read-only motion state strip and Command Deck readiness cards without a new main-menu page.
- Four new Admin/No-Code content types for motion identity, wake, sail response and water displacement.

## Authority
M267 owns replicated world entities and M268 owns position, velocity, heading, destination, speed legality, route legality, collision and reconciliation. M287 only renders confirmed presentation. It cannot set a destination, change speed or heading, rotate the canonical ship transform, decide route/collision, convert camera-joystick input into ship movement or promote water/sail visuals to authority.

## Master locks
Tap-to-Sail remains the mobile movement model; a tap behind the ship may route directly without a forced forward arc. The lower-left virtual control moves only the camera. The lower-right primary attack cluster and the sea-chart center stay unobstructed. Islands remain hard navigation obstacles, while units and loot remain non-blocking. Mobile, Web and Desktop use the same world and gameplay truth.

## Visual and asset lock
Wake, foam, water displacement and sail motion remain separate Godot runtime layers and are never baked into the canonical ship GLB. Stable sockets and asset IDs allow final class-specific motion scenes to replace placeholders without changing movement code. `assets/production` and `assets/reference_only` remain separated.

Initial-production ships remain complete individual 3D/GLB models. Hull, bow, stern, deck, masts, sails and characteristic design parts stay together. M287 requires no modular hull, detachable part, separate sail mesh or bone; optional authored animation hooks may be added later without turning the ship into a module kit.

## Clean-room reference
Seafight and Battle of Sea inform only naval immediacy, silhouette readability and satisfying motion feedback. No proprietary model, texture, VFX, sound, UI layout, formula or timing is copied.

## Intentionally open
Final authored water/sail assets, wake curves and opacity, bow width, turn curl, waterline, anchor ripple, sail angles/frequency, correction feedback, motion audio/haptics and simultaneous-ship budgets remain open until native gameplay QA.

## Validation
- 453/453 static regression and integration tests passed (436 function tests + 17 unittest tests).
- 553/553 JSON files parsed successfully.
- Release identity aligned to M287 / 0.287.0 / build 287.
- ZIP integrity is verified during the final packaging pass.
- Native Godot render/audio/device QA remains NOT_EVALUATED because this execution environment contains no Godot binary or export templates.
