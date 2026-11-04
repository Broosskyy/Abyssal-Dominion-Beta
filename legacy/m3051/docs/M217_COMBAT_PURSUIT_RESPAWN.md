# M217 — Combat Pursuit, Respawn Safety & Salvo Readability

M217 closes the defeat-loop problem where the previous NPC engagement could visually/behaviorally continue into a fresh respawn. The five gameplay master references and the M213/M214 camera/world composition remain locked.

When a player target becomes sunk or respawn-protected, hostile AI clears that target, enters RETURN, and receives a local reacquire block that extends beyond the existing respawn protection window. Passive-until-attacked encounters also clear their provoked state after the player defeat. This prevents the same NPC from camping the harbor return while preserving the existing authoritative player protection duration.

M217 also exposes a short presentation-only hostile broadside-threat metadata window. The target HUD can show `SALVE` while that hostile firing window is active. Damage, range, reload, movement, collision, respawn protection duration, rewards, loot values and pickup radius are unchanged. Mobile, web and desktop use identical world/combat logic.
