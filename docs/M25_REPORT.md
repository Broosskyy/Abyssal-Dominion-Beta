# M25 — Encounter Ecology + Boss Hunt Pass

## Direction lock
The project-owned gameplay mockup remains the visual master. M25 expands original encounter/gameplay systems toward a modern persistent naval-action loop without copying third-party code, UI, names, assets or balancing.

## Implemented
- Enemy AI state machine: PATROL / PURSUE / ENGAGE / RETURN.
- Spawn-anchor leash, safe-zone disengagement and timed target loss.
- Archetype-specific range keeping retained from M24, with scout orbit pressure.
- Final regular encounter slot promoted to a stat-scaled elite.
- Boss health phases at 66% and 32%, increasing tempo/speed and final-phase damage.
- Tropical boss hunt replaced by an original procedural Tide Leviathan encounter while desert/snow retain admiral ships.
- Compatibility-safe procedural monster body/tentacle silhouette and monster HUD classification.
- Common / uncommon / rare / epic / legendary salvage tiers with reward multipliers and differentiated native chest materials.
- Boss status and target HUD show boss phase / monster classification.

## Validation
- M25 static contract: 5/5 PASS.
- M24 + M23 + M22 regression contracts: 7/7 PASS.
- Platform contract: 19/19 PASS.
- No Godot executable is installed in this execution environment, so a real Godot 4.7.2 parse/run/export remains required before visual/runtime acceptance.
- Bundled historical Web output is not evidence of the M25 render until rebuilt with Godot 4.7.2.
