# M200 — Gameplay Visual Composition Pass

M200 is the first broader gameplay-screen composition pass after the V3.8 visual-master lock. It strengthens the visible relationship between ships, projectiles, hit feedback, loot in the water and large island silhouettes without changing gameplay authority or world parity.

## Changes
- Loot halos are larger and high-value/readable pickups receive a visual-only vertical sea beacon. Pickup collision, rewards and lifetime are unchanged.
- Cannonballs gain a stronger gameplay-zoom silhouette and brighter/longer trails; existing ammo-specific profiles remain.
- Muzzle flashes and impact feedback read more clearly, with a visual-only impact ring.
- Large procedural islands gain a small visual-only coastal navigation anchor to improve silhouette hierarchy and orientation. Island collision/navigation remain unchanged.
- Mobile/Web/Desktop still receive the same world, objects and gameplay VFX. Only responsive interface sizing/spacing/safe areas may differ.

## Verification
Static source/tests/JSON/ZIP verification only. Native Godot, Android and desktop visual acceptance remains pending.
