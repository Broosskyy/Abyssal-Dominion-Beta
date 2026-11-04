# M26 REPORT — Responsive Menu + Mobile UX Pass

## Direction lock
- Project-owned mockup remains the visual master for gameplay composition and HUD.
- Persistent naval-action depth remains the gameplay-system target, implemented with original code/content/balancing.
- Mobile/Web/Desktop presentation is treated as a shared product surface, not an afterthought.

## Implemented
- Responsive in-game captain menu overlay.
- Real navigation targets for Events, Quests, Market, Guild, Chat, Achievements, Rankings, Bonus, Group and Captain Menu.
- Menu opening cancels tap-to-sail navigation and stops ship steering to avoid accidental movement behind overlays.
- Compact/portrait bottom quick tabs for Events, Quests, Market and Guild.
- Top navigation remains usable as a fast menu-page switcher.
- Touch close target enlarged to 42×42 logical pixels.
- Offline-safe content: no invented live chat, guild roster or ranking data.
- Existing Shipyard, Arsenal, world map, combat, progression and encounter systems remain independent.

## Runtime note
A fresh Godot 4.7.2 engine run/export is still required for visual acceptance. The bundled historical Web build is not evidence of the M26 render.
