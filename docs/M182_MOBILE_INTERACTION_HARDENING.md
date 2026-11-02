# M182 — Mobile Interaction Hardening

M182 continues the M177 evidence-repair sequence after M180 and M181.

## Input ownership

- Inventory, journal, command menu, settings, Admin and Meta now share one world-input gate.
- Tap-to-Sail, repair, boost and fire cannot leak through an open modal.
- The gameplay camera pauses behind every modal state instead of only the original four.

## Respawn protection

- The remaining protection time is visible as a live HUD status chip.
- Firing a weapon deliberately ends protection and communicates that change.
- M181 damage immunity and enemy target-reacquisition blocking remain unchanged.

## Loot guidance

- Spawned loot participates in the bounded world-marker budget with a dedicated priority.
- Nearby loot receives a readable name and distance label.
- Tapping a visible loot marker creates a Tap-to-Sail course to the pickup.
- M181 Area3D and proximity collection remain the only collection path; markers do not grant rewards.

## Validation boundary

Static tests verify input routing, M180/M181 preservation, release identity and data contracts. Godot 4.7.2 and real Android device validation remain deferred as requested.
