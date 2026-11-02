# M126 — No-code Content Platform Foundation

Both Web Admin and Ingame Admin are clients of one ContentAdminService. They do not own separate truth.

Supported authoring types: items, ammunition, weapons/cannons/harpoons/support, ships/designs, NPCs, monsters/bosses, loot tables, quests/trials, encounters/bonusmap waves, events/LiveOps, shops and payment products.

An administrator can create a stable ID, fill schema fields, reference existing/new AssetSlots, validate, schedule, publish, disable and roll back. New supported records do not require a client code deployment.

Important boundary: M126 implements local draft authoring and runtime additive resolution for ships/ammo/weapons first. Other types have schemas/service contracts but their gameplay consumers still need migration. Production publishing, staff identity, asset upload, payments and entitlements require the future authenticated backend and are intentionally not faked locally.

Assets remain replaceable: content ID is stable; GLB/icon/VFX/LOD payload lives behind AssetSlots. Thus a new ship can be authored in admin with stats/unlock/shop/mastery + SHIP asset slot, while the final GLB can be uploaded/replaced separately.
