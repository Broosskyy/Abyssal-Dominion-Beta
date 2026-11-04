# M129 — Rules + Specialized Runtime Migration

This pass moves more old hard-coded gameplay into the shared admin/live-config model:
- rotating missions, daily/weekly goals and rewards, event milestones/rewards and chain stages
- loot pickup lifetime/radius/material pools and optional dynamic loot-table rewards
- admin-extendable boss→ship rewards and active dynamic ships in the shipyard roster
- world/rules RBAC permissions and publish validation
- a complete disabled Stormtide example package demonstrates item + loot table + NPC + quest + shop + event composition without a code edit.

Static constants remain only as local compatibility fallbacks where retained. Production truth is intended to be a versioned verified snapshot.

No arbitrary executable code is accepted from Admin. New algorithms still require a reusable engine component once; new content using existing schemas/components does not.
