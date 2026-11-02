# M128 — Dynamic Content Runtime

M128 connects the M126 Content Studio to more gameplay consumers.

No-code additive runtime now covers ships, ammo, weapons, action items, harpoons, support payloads, generic NPC/monster definitions, loot tables, quests, shops, events and bonusmap/encounter wave definitions.

Safety/design rule: "everything without code" means administrators compose supported data schemas and whitelisted behavior components. Admins cannot upload arbitrary executable GDScript. A genuinely new mechanic/algorithm still requires engineering once; after that mechanic exists as a reusable behavior component, unlimited content using it can be authored without code.

Web Admin and Ingame Admin share the same content/RBAC contracts. Production content remains versioned/server-authoritative and is not faked by local drafts.
