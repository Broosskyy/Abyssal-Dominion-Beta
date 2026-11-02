# M241 — Crew & Officers Vertical Slice

M241 implements the first canonical V3.8 Crew/Officer runtime after the M239 convergence audit and directly integrates the M240 Repair Master / Shield Master sustain contracts.

## Canonical rules now enforced

- Crew remains abstracted; no sailor-by-sailor micromanagement exists.
- Officers have stable IDs, family, tier, role, quality, level, traits and a passive contract.
- Repair Master and Shield Master are separate officer families and can be assigned at the same time when slots allow.
- Only assigned officer contracts select the active Repair Master / Shield Master tier used by M240 sustain logic.
- An officer cannot occupy multiple slots at once.
- Roster ownership and slot assignment persist in local saves.
- M240 saves migrate their previous repair/shield tier into the M241 local roster so prototype progress is not silently lost.
- Live ownership, progression, purchases and reward grants remain server-authoritative boundaries.
- Core officer roles must have planable earnable acquisition paths; no mandatory gacha-only progression is introduced.

## UI

The Command Deck Equipment page exposes a compact mobile-friendly Crew & Officers section. It shows slot occupancy, assigned contracts, officer quality/level/traits and locked higher contracts with their intended acquisition direction. A slot button cycles only through locally owned, currently unassigned officers.

## Scope boundary

The V3.8 role registry (Master Gunner, Harpoon Master, Navigator, Shipwright, Quartermaster, Surgeon) is represented, but M241 only activates the Repair/Shield sustain families. Combat, movement and economy modifiers for the other roles are intentionally not invented in this milestone.
