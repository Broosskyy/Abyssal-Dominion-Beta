# Abyssal Dominion — M270 Production Report

Master basis: V3.8.

M270 adds the Authoritative Combat State / Reload / Status Effects / Projectile Resolution Foundation on top of M269. Reload completion, combat phase, status application/refresh/removal, DoT/HoT ticks, repair/shield resource changes, projectile spawn/lifecycle/impact and combat-state revisions remain server-owned. Local UI/VFX may display predicted reload progress and interpolate projectiles but can never confirm impact, damage, healing or state mutation.

Genre/UX references remain Seafight and Battle of Sea for naval combat readability and cadence only; implementation is clean-room and Abyssal-Dominion-specific. No final balance/timing values were invented. TEST/GLOBAL remain isolated.

Production gaps remain: real server scheduler/simulation, projectile collision/impact, status scheduler, measured tuning, and native multiplayer latency/jitter/loss/load/adversarial QA.
