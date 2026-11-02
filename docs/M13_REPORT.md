# M13 — Splash, local profiles and captain home

Godot-native Splash → Login/Register → captain homepage → ZUR SEE → existing game.
The homepage shows the actual reconstructed Clipper in a separate 3D showroom,
level/coins, update notes and logout. The player name also appears over the ship.
Menus use native scrollable controls and a compact layout on short viewports.

## Account boundary

**Login/Register means passwordless local profile slots, NOT online authentication.**
No email, password, hash, token or external account endpoint is used. Other users
of the same browser/device can open the profiles. Up to eight named slots have
separate local saves. Guests never save. No cloud sync or multiplayer crossplay.
The independent M12 WebSocket transport probe is unchanged.

Profile names and IDs are validated. Corrupt registries are protected against
overwriting; writes use a temporary file and rename. A save failure prevents
leaving the game. A valid M12 legacy save can explicitly be copied into an empty
profile without changing the original or overwriting a profile save/backup.

## Game lifecycle

No combat runs behind the menus. Real resource-loading status drives the loading
bar. Return-to-home stops ambience and removes the active game. Projectiles,
effects and navigation markers belong to that game root, not the application.
Transitions are deferred until input dispatch completes. The static ship preview
uses guarded deferred camera fitting, not a dangling frame coroutine.

## Reconstruction evidence

`tools/map_entry_metadata.py` reads the original metadata skeleton and Unity
inventory preserved in M12. `m13_entry_metadata.json` records original UILogin,
UIRegister and UIResetPassword fields/method names and login/register panel IDs.
The original declarations include password, email and recovery fields. Their
backend implementations are not recovered; the local profile UI is a deliberate
test substitute, not a recreation of working online accounts.

The temporary workspace was cleaned during this milestone. The canonical M12
archive was restored, and M13 source was rebuilt on it. Earlier temporary M13 UI
bitmap extracts and screenshots were lost. This final reconstruction therefore
uses native flat menu panels and the existing M12 test icon, not a claimed recovered
original menu/logo image. Original ship/island assets from M12 remain intact.
The simplified sail tint remains because its referenced bitmap is unavailable.

## Verification

Actual Godot 4.5.1 Compatibility runtime; configured target 4.7.2 remains untested.
**213/213 engine checks passed** after recovery (176 regressions + 37 M13 checks).
The Web export was rebuilt successfully. The final M13 browser rendering is
**not verified**: browser downloads timed out and the final attempt encountered a
cancelled network approval. No permission workaround was attempted.
`qa_m13/capture_report.json` records this block, not a fabricated pass.
`tools/capture_entry_web.cjs` is provided for the next authorized local check.
It is designed to use real Godot WebGL and mouse/keyboard/touch events for login,
registration, gameplay, return, logout, browser reload and guest mode. It verifies
the actual LineEdit value before submitting. It has not been run against this
recovered final build. No new M13 screenshots are included; M12 screenshots are
historical only. Physical device/gamepad tests remain outstanding.

Android/iOS/native desktop export presets remain prepared, not signed/tested device
releases. Browser storage depends on origin and may be unavailable in private mode.
No public hosting, server credentials or production account system is included.
