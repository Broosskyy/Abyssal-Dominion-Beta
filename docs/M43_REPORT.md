# M43 — Ammo Visual Identity + Combat Detail UX

- Added per-ammo projectile trail profiles for all eight early cannon ammunition types.
- Added distinct impact visual profiles for Chain, Piercing, Ember, Venom, Shatter, Spectral and Explosive ammunition.
- Visuals remain presentation-only; gameplay values still come from CombatCatalog/runtime combat logic.
- Mobile picker supports long-press (420 ms) to open a detail card; tap still selects/uses immediately.
- Desktop right-click opens the same detail card, left-click selects/uses.
- Detail cards show role/category, damage/effect, range, duration/cooldown where relevant, stock and source hint.
- Picker continues to block world sailing input while open.
- No native Godot 4.7.2 binary was available in this environment; static source/JSON validation only.
