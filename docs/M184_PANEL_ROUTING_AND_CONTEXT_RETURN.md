# M184 — Panel Routing & Context Return

M184 fixes the remaining overlap path beneath the M183 Command Deck. Full-screen child panels now have one central owner and return to the menu page that opened them.

## Runtime behavior

- The Command Deck closes before Shipyard, Progression Track, Ship Mastery, Harbor Workshop, Progression Hub or Captain Meta opens.
- Only one routed full-screen panel may own input.
- Closing a child panel returns to Home, Progress or Equipment according to the opening context.
- Nested Mastery/Progression → Shipyard transitions preserve the original return page without briefly reopening the menu.
- Persistent panels are hidden and retained; transient panels are released.
- `external_panel_open` blocks sailing, camera movement and weapons together with the existing modal keys.
- A short UI action guard prevents the closing key/tap from also firing a salvo.

## Presentation cleanup

- Shipyard and Progression Hub headers no longer expose old milestone numbers to players.
- Command Deck actions now use named routing helpers instead of constructing overlapping screens independently.
- M183 page hierarchy, 56-unit touch targets, safe areas and conditional Admin visibility remain unchanged.

## Validation boundary

The source package is statically regression-tested. Native Godot 4.7.2 parsing/rendering and Android/iOS device acceptance remain deferred until the required engine/device environment is available.

