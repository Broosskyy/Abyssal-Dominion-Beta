# M100 — Major Integration / Quality Gate

M100 deliberately audits M89–M99 before adding more breadth.

## Corrected regression
M97 applied the `npc_shadow_distance` quality value through GeometryInstance3D visibility range. That could hide an entire NPC hull beyond the intended shadow hint distance. M100 removes that behavior. NPC hull visibility is independent again. The shadow value is retained only as metadata/hint until a real renderer-specific shadow-distance policy is validated natively.

## Nameplates
The existing M66 quality profile's nameplate distance is now actually consumed by the main world-label renderer. Player, selected target and boss nameplates remain exempt so combat readability is not lost.

## Permanent world
The three prepared irregular silhouettes are now wired as replacements inside the existing one-hero-detail cap:
- cliff/cove -> small cliff
- thin spit -> long hook
- long shoal -> split rock

Haven's Reach replaces two inherited dressing positions with a pirate lantern variant and skull sign. The inherited 30-module count does not increase.

## Guild island
A visual shield/objective layer is added: one core and two nodes. It is explicitly presentation-only: no capture, live shield combat, ownership or persistence authority.

## HUD
Guild detail panels now try the opposite side of the main guild interaction panel when the preferred placement would leave the safe area. Touch/mouse/gamepad focus behavior remains intact.

Halloween and Admin Mode remain available. No server entitlement, live economy or persistent online authority is claimed.
