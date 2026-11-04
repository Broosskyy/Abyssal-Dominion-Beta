# M82 — Mobile/Desktop Responsive + Crossplay Readiness + PL1–5 Content Optimization

M82 keeps the master production order intact while improving the same systems already introduced in M70–M81.

- Added `InputDeviceProfile`: touch/mobile, mouse+keyboard and gamepad are presentation/input modes only. Gameplay values never branch by device.
- `NauticalLayout` now exposes a HUD/input profile and improves large-desktop scaling while preserving the existing mobile density/touch rules.
- Mobile presentation budgets now include marker size, HUD text-scale metadata and first-dock timing. Compact-phone touch targets remain 56+ logical units.
- Added a transport-neutral `GameplayIntentContract` for future crossplay. Touch/mouse/keyboard/gamepad can map to the same gameplay intent vocabulary; no sockets/accounts/matchmaking/server authority are implemented.
- Player input records only local intent metadata for readiness/debugging. It is not network traffic and does not alter gameplay resolution.
- PL1–5 encounter cadence is corrected toward the master learning order: no boss/elite in PL1–2, first monster at PL3, elite/admiral presentation from PL4 onward. Normal PL1–5 NPCs remain neutral until attacked.
- Haven's Reach now wires barrel-rack and small-boat slots.
- Wreck profiles use broken-mast/rope-tangle alternatives without increasing the three-object context cap.
- Added a shallow-coast visual layer using stable rock/foam slots with device-aware visibility budgets.
- Added six polished replaceable cross-platform/input UI icons and eight new stable model slots.
- The exact P0 first-13 asset wave remains the top final-asset priority; secondary props are prepared but do not displace it.

No backend/server authority, accounts, matchmaking or real multiplayer transport is claimed. Native Godot 4.7.2 parsing, Android/iOS/desktop screenshots, controller QA and real device profiling remain required.
