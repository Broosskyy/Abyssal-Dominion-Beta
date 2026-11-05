# Sea-chart presentation pass — Seafight / Battle of Sea references

Source: main at `2ecea62ce153e7d157eae7b678cecc691b8e81cc`, data-49.
The supplied 207169/207171 screenshots show the current game. The five new
reference screenshots (205767, 205791, 205795, 206873, 206929) and the 22.78-second
206876 video establish the direction: quiet blue/teal water, small ship captions,
thin health bars, a clear playfield, and combat actions grouped at the edge.

## Implemented

- Water keeps a world-space surface texture but uses a restrained navy/teal palette,
  smooth depth variation and faint moving detail. Sharpened grain and long bright
  wave stripes are removed. Regional tint remains functional.
- Ships are drawn before their labels. Names, small rank marks and thin hull/shield
  bars stay a fixed screen size when zooming. Exact numbers remain in the top HUD
  and target card. Deck slots and consumable states no longer form a tall block
  beneath the captain; mounted deck marks sit in an edge strip, while detailed deck
  information remains in the ship window and active supply states on their buttons.
- Caption placement checks measured sprite bounds, other labels, screen edges and
  visible HUD. The captain and selected target reserve space first. In tight groups
  they can move above or beside the hull, with a subtle attachment line. Ordinary
  NPC captions yield when no nearby clear space remains. Ship positions, collision,
  combat damage and movement are unchanged.
- Four special ammunition slots share the utility grid above the bottom combat row.
  Their hit areas match the ordinary ammunition slots. The existing two-page item
  controls retain their actions. The four special source images contain a baked
  checkerboard: runtime atlas previews sample only the opaque projectile core, and
  the circular icon mesh stays inside its UV rectangle. No source PNG is changed.
- Status messages appear briefly below the header instead of staying over the
  lower playfield. A new message resets the four-second timer. Docking instructions
  remain visible while docked, and the logbook retains the message history.

## Verification

`tests/chart_presentation_test.gd` covers close hulls at 1280×720, 844×390,
720×405 and 2340×1080, all three HUD sizes and three zoom settings. It checks
caption priority, collision with sprites and HUD, bounds, special ammunition hit
areas, real selection actions, unchanged captain progress and message expiry.
It runs as part of the existing Android/data build together with the prior suites.

Actual OpenGL/llvmpipe renderer captures at 1536×709, 844×390 and 2340×1080 were
inspected locally using Godot 4.6.3. The publication workflow provides the required
Godot 4.7.2 validation and its own renderer captures. Controlled close-encounter
fixtures are not device footage. A physical Android playtest is still needed.

## Remaining limits

The original low-resolution NPC atlases still differ from the eight-view starter;
this pass does not create new fleet art or perspectives. Existing harbor scenery,
island geometry and local-only gameplay remain as before. This is compatible game
code and presentation data for bootstrap 305901; no native/updater change is made.
