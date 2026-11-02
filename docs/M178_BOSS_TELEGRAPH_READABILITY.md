# M178 — Boss Telegraph Readability

M178 turns the M177 warning state into an actual world-space gameplay telegraph. Targeted casts snapshot the player's position at cast start; sailing outside the configured hit radius before the timer expires dodges the mechanic. Boss self-casts remain anchored to the boss.

## Presentation contract

- One danger ring exists per active boss cast.
- Silver, Gold, Abyss and Legendary encounters have distinct data-driven accent colors and stable replaceable VFX slots.
- The HUD warning remains below the locked top/objective region and adds remaining seconds plus a progress bar.
- Reduced Motion removes ring scaling. Effect Intensity scales emission, while critical readability keeps a minimum alpha of 0.42.
- Replacing the optional PackedScene cannot change timing, hit radius, damage or authority.

## Control and authority locks

Tap-to-Sail, the bottom-left camera-only joystick and the bottom-right combat cluster are unchanged. Local damage resolution remains prototype behavior composed from existing combat primitives; the online production path remains server-authoritative.
