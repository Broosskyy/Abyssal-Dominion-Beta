# M20 — Ship Readability, Wake, Combat VFX & Mobile Comfort

M20 continues directly from the M19 Godot 4.7.2 / Compatibility-renderer baseline. It does not reset progression, captain journal, harbor, encounter, targeting, save, sector or cross-platform systems.

## Ship readability

The procedural fallback ship receives a silhouette/readability pass using inexpensive native primitives: darker keel, stern gallery, captain cabin and roof, side trim, visible deck cannon barrels, bowsprit and a player-only cyan captain pennant. This is deliberately a fallback-quality upgrade rather than a replacement for recovered or future production GLB vessels. Socket and collision contracts are unchanged.

## Wake and sea motion feedback

The former two straight wake strips now add a stern-foam patch, longer speed-scaled trails and a small turn-dependent divergence. Opacity remains driven by actual vessel speed. The implementation uses unshaded alpha planes and remains Compatibility/Web safe.

## Combat presentation

Muzzle flashes now combine the short emissive flash with a fading smoke puff. Hull impacts add four cheap spark streaks plus the existing flash/smoke treatment. Cannon trails are slightly longer and narrower. Projectiles that reach the end of their lifetime create a short native water splash before being removed. Collision, damage, ammo consumption, range and reward logic are unchanged.

## Mobile comfort

Compact/mobile combat targets are larger: fire, utility, ammunition and helm hit areas receive modest increases. Helm drag now has a radial 12% deadzone and remaps the remaining travel to full input, reducing accidental turns from tiny thumb movements while retaining full-speed steering. Existing tap-to-sail, two-finger pinch and HUD blocking rules remain intact.

## Validation boundary

Static M20 contract tests and the existing Python preview server suite can be run without Godot. A true engine parse/export still requires the Godot 4.7.2 executable and matching export templates. If the environment has no engine binary, the bundled historical Web build must not be described as a fresh M20 render.
