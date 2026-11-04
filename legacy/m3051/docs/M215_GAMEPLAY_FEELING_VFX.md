# M215 — Gameplay Feeling & Sea/Combat VFX

M215 keeps the V3.8 and five-master-reference camera/composition locks and improves only the visible moment-to-moment feedback. The higher/wider oblique gameplay camera needs movement, projectiles, impacts and loot to remain readable without filling the screen with UI.

The ship wake now has an additional visual-only stern break and long wake spine driven by real ship speed. Water receives sparse whitecap detail on top of the M198/M199 material. Projectile splash silhouettes are identical across mobile/web/desktop, cannon impacts add a short water shock ring, and loot collection receives an immediate world-space ring while preserving the existing prioritized HUD reward notice.

No damage, range, reload, steering, ship speed, collision, loot reward, pickup radius, navigation or Tap-to-Sail rules are changed. Native Godot/device visual QA is still required before treating the values as final art tuning.
