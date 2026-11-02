# M42 — Combat Visual Identity + Mobile Cooldown Readability

- Added stable original icon slots for all eight early ammo types and the current action/supply items.
- Added `combat_visual_contract.json`: icon and VFX profiles are visual-only and never define gameplay values.
- Added lightweight runtime `CombatVfx` pulse feedback for ammunition impacts and action-item activation.
- Every early ammunition type now has a distinct visual slot instead of reusing only three generic ammo icons.
- Combat picker shows cooldown progress arcs directly on item icons plus remaining seconds.
- Added a compact four-slot readiness strip for Repair, Speed, Veil and Barrier without turning Mobile into a 20-button MMO hotbar.
- Placeholder SVGs are original Abyssal Dominion production placeholders and can be replaced through stable visual slots later.
- Static source validation only; native Godot 4.7.2 Android/iOS/desktop QA still required.
