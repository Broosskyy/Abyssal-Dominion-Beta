# M183 — Unified Command Deck & Menu Overhaul

M183 consolidates the existing M168–M182 menu systems under one mobile-first command-deck shell. It does not replace the seekarte or add a second gameplay surface.

## Player-facing changes

- The command deck now has a persistent active-page title, short context, destination selector, Back and Close.
- Back follows real page history and only closes from the root page.
- The home page is grouped into On Sea, Ship & Equipment, Captain & Community and System.
- Touch layouts use the safe area, eight-unit edge clearance, full available width and 56-unit minimum actions. Desktop uses a wider 980-unit reading column.
- Admin is omitted unless the local authorized runtime is enabled. Production authority remains server-side.
- Existing progression, shipyard, arsenal, bonusmap, quest, event, guild, meta, settings and admin systems remain canonical; this milestone improves how players reach them.

## Masterkonzept V3.8 alignment

- The seekarte remains the heart of the game and its center stays clear during play.
- Mobile continues to use Tap-to-Sail, a camera-only lower-left wheel, and the lower-right combat cluster.
- Quest details live in the log; the map shows only prioritized objectives.
- Harbor services remain contextual destinations rather than permanent HUD clutter.
- Sensitive payment, guild and staff actions keep their existing server-authority boundary.

## Validation boundary

Static contracts and JSON integrity are validated in this source package. Godot 4.7.2 parsing, rendering and Android/iOS device acceptance remain outstanding because the engine/device toolchain is not installed in this environment.

