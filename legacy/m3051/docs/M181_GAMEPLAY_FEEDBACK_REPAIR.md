# M181 — Gameplay Feedback and Recovery Repair

M181 follows the M180 evidence-led mobile HUD/water pass and closes the runtime problems reported in the same M177 Android test.

## Tap-to-Sail

- A water target behind the ship no longer applies permanent minimum forward throttle.
- The player ship brakes and pivots along the shortest heading before accelerating.
- Camera-wheel panning remains camera-only and never steers the ship.

## Defeat and respawn

- Sinking displays a persistent, centered defeat overlay with return countdown.
- Navigation is cancelled and the ship is removed from active enemy targeting while sunk.
- Respawn occurs at the configured safe spawn with six seconds of damage and enemy-reacquisition protection.
- A prominent respawn confirmation communicates the protection window.

## Loot and rewards

- Qualified sinks show earned XP and explicitly announce loot in the water.
- Area-enter pickup remains canonical; a bounded proximity fallback prevents missed collection caused by the small pickup sphere versus the large ship hull.
- Pickup notices show the exact gold/repair and salvage material result using the priority-aware reward lane.
- Existing mission, quest, wallet, inventory and server-authority paths are preserved.

## Validation boundary

Static regression coverage verifies the runtime wiring and M175–M180 preservation. Godot 4.7.2 parsing, Android packaging and real-device feel remain physical validation requirements.
