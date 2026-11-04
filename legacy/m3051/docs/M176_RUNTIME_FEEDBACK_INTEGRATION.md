# M176 — Runtime Feedback Integration

M176 connects the M175 presentation foundation to actual combat and bonus-map events. It does not create a parallel combat, loot or reward system.

## Connected paths

- ShipHealth: damage, barrier, shield, armor, repair and heal presentation.
- ShipWeapons: support-cannon source attribution for hull and shield restoration.
- EnemyShipAI: boss phase and enrage announcements after the existing phase profile changes stats.
- BonusMapWaveDirector: runtime-final-wave boss detection plus wave/boss/completion presentation.
- GameHud: a priority-aware, deduplicated notification lane below the fixed top HUD.

## Production acceptance

Validate dense volleys, DoT plus armor mitigation, self-repair, ally support, phase 2/3 transitions and all four bonus-map finales on compact phones. Critical combat state must remain readable with Reduced Motion, Reduced Flashes and low effect intensity.
