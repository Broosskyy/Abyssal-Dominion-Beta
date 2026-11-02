# M83 — Player-customizable HUD / UI Layout

This milestone adds a Seafight-like player HUD arrangement concept while keeping Abyssal Dominion's own UI and cross-platform rules.

## Implemented
- Settings now expose `HUD / UI ANPASSEN` during an active sea session.
- Fullscreen edit overlay works with touch and mouse.
- Nine logical HUD groups can be dragged: captain/status, mission, objective, minimap utilities, movement/camera, combat, quickbar, target info and currencies.
- Positions are stored locally as normalized safe-area offsets, not fixed pixels.
- Mobile portrait/landscape and desktop HUD profiles remain independent through the existing M82 profile system.
- Critical elements are clamped to the safe area.
- Current profile can be reset from the editor.
- Layout changes are presentation-only and do not alter movement, damage, cooldowns, rewards or future crossplay authority.
- Default responsive layout remains the fallback when no custom layout exists.

## Technical boundary
This is local UI customization. It is not account/cloud synchronization yet. When the real account/backend phase arrives, the normalized layout document can optionally become an account preference while gameplay authority remains server-side.

Native Godot 4.7.2 parser/runtime/device QA is still required, especially drag interaction on Android/iOS and unusual safe-area/notch configurations.
