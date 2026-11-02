# M186 Production Report

Status: `M186_QUEST_TRACKING_NAVIGATION_STATIC_VERIFIED`

M186 adds a single persistent tracked objective shared by core, dynamic regional and event quests. The selected objective owns the sea HUD mission lane, one priority world/edge marker and one minimap ring. Course setting reuses Tap-to-Sail only for an existing matching world node; unavailable targets remain explicit and no fake route, teleport, spawn, reward or online authority is introduced.

Validation before packaging:

- 39/39 Python regression contract files pass.
- 439/439 JSON files parse recursively.
- Release identity is M186 / 0.186.0 / build 186 / Masterkonzept V3.8.

Native Godot/device testing remains open because the required runtime is not installed in this environment.
