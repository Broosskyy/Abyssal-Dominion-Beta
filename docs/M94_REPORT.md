# M94 — Admin Mode + Halloween Event

M94 implements the requested local admin mode and an original Halloween seasonal event.

ADMIN MODE
- AdminModeRuntime is enabled by default for this local development build.
- A floating ADMIN button opens a touch/desktop overlay.
- Commands include map-level teleport, local Halloween visual spawning, test kit + Gold, full repair, invulnerability toggle, Halloween on/off, phase cycling, event currency, guild-island relation preview and sector rebuild.
- The Command Deck also has an Admin page.
- Client admin mode is explicitly not production authority. Future live accounts/economy/guild/war/event scheduling require authenticated server-side admin permissions.

HALLOWEEN — NIGHT OF THE DROWNED
- Event ID: halloween_abyss_01.
- Three local phases: The Fog Rises, Drowned Armada, Abyssal Midnight.
- Halloween world layer begins from map level 2 and adds a portal, haunted wreck and phase-dependent fleet visual slots.
- Guild islands receive a Halloween event decoration layer.
- Gravefire Shot is a real local ninth cannon ammunition type using the existing burn pipeline.
- Gravewake Lantern is a real local tactical item using the existing armor-break pipeline.
- Event contracts include quests, Drowned Embers currency, milestones, preview shop and Drowned Corsair reward-design slot.
- Event NPC/admiral/monster/boss visuals are present as replaceable event presentation slots. Their authoritative event combat/reward backend is not fabricated.

Existing progression, Tap-to-Sail, guild-island-from-map-2, HUD customization, no-angle-damage and the P0 first-13 asset priority remain intact.
