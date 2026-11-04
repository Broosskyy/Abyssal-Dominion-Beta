# M98 — Guild Island PL2 Interaction Depth + Visual Defense States

The map-2 guild island path was audited first: WorldMapSystem already calls GuildIslandComposer for map level >=2. M98 deepens that existing path instead of creating a second system.

- Interaction range is 10m and the island exposes dock, guild, defense, facilities, harbor overview and tower-range preview.
- Harbor overview distinguishes local docking context from future server-required repair/storage services.
- Tower range rings can be toggled as presentation. They expose the existing range contract but never fire or chase.
- Cannon and chain towers now support reversible visual states: intact, damaged and disabled. These states explicitly do not represent persistent damage.
- Stable replacement slots exist for all three tower states.
- Admin Mode can cycle tower states and toggle range previews for QA.
- Tower combat contract remains target/range/reload/damage_definition. Broadside-angle damage remains forbidden.
- Siege loss still cannot imply guild deletion or permanent destruction.
- Ownership, membership, treasury, vault, diplomacy, war, conquest, upgrades and persistent damage remain future server-authoritative systems.
