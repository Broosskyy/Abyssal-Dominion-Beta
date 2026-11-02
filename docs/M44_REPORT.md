# M44 — Persistent Combat Quickbar + Status Readability

- Four actionable quickslots are now part of the sea-map HUD.
- Bindings are saved per owned ship through PlayerInventory/GameState.
- Supported bindings: cannon ammo, action items, supplies, and harpoon mode.
- Assignment happens from the existing long-press/right-click combat detail view.
- Default bindings: Iron Shot, Emergency Planks, Storm Sail, Abyssal Veil.
- Quickslots show stock, cooldown, selected ammo/mode state, and supply-active state.
- Player status chips remain compact; selected targets now also expose important debuff state.
- The bar intentionally stays at four slots to preserve mobile readability.
- No fake server authority; this remains local prototype persistence.
- Static source/contract validation only. Native Godot 4.7.2 device QA is still required.
