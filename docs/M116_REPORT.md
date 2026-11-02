# M116 — Abyss Systems Deepening

M116 first fixes two integration debts: M114 Gold mastery now uses the existing roster API, and M115-era Gold/Build/Corruption/Abyss state is embedded in Voyage save payloads.

Corruption is no longer metadata-only: ShipHealth consumes its incoming-damage multiplier and PL26+ encounter loot consumes its capped reward multiplier. Opt-in/cleanse semantics remain unchanged.

Three Abyssal Harpoon payloads are now runtime-selectable through the existing harpoon system. Stable equipment hooks cover Corruption Gear and Advanced Castle families.

Abyss Bonusmap now has a real six-wave runtime state: ship waves, monster waves 3/6, final Guardian gate, wave rewards, mastery XP, completion materials and persisted state. It has a unique local instance identity. Truth boundary: encounters are still supplied by the current world EncounterDirector rather than a dedicated isolated map scene/scene-tree transfer. That dedicated world instance remains future work.

Native Godot 4.7.2/mobile/web/desktop QA pending.
