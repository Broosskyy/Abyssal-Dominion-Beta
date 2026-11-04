# M175 — Feedback Presentation Foundation

M175 converts the new production/design lock into a runtime-readable presentation contract. It deliberately extends the existing CombatFeedback, CombatVfx, HUD, settings and loot paths rather than introducing parallel gameplay systems.

## Acceptance focus

1. Camera joystick is camera-only; Tap-to-Sail remains the ship input contract.
2. Primary combat remains bottom-right and the world center stays readable.
3. Damage numbers aggregate more aggressively when the mobile feedback queue becomes dense.
4. Critical hits keep priority and a larger visual scale.
5. Reward rarity changes presentation intensity without changing reward authority.
6. Reduced Motion, Reduced Flashes and effect intensity reduce presentation cost without hiding critical gameplay state.
7. Presentation configuration cannot authorize damage, loot, currency, inventory, commerce or entitlements.

## Next visual-production pass

Replace generic primitives through stable VFX slots and author event-specific profiles for Halloween, Winter and Abyss Invasion. Validate all tiers on 360×800, 393×873, 412×915 and tablet/desktop reference devices before raising effects budgets.
