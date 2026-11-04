# M49 — Regional Equipment, NPC Identity & Harbor Production Sockets

- Added six finite PL6–15 regional equipment modules across Weapon, Defense, Support and Mobility slots.
- Module ownership and equipped slots persist per ship. No infinite raw-stat ladder and normal crafting cannot destroy valuable equipment.
- Module effects are applied by gameplay wrappers: cannon/harpoon damage/reload, armor, speed and support effectiveness.
- Added nine regional NPC combat-role identities across Stormreach, Ember Shoals and Veil Sea plus regional admiral identity metadata.
- Added four stable harbor visual sockets: Workshop, Merchant, Repair Yard and Support Pier. Procedural placeholders remain functional until final GLBs exist.
- Added local SupportContributionTelemetry for effective hull healing, shield restoration, successful actions and unique targets. Overheal contribution is always zero and telemetry grants no rewards.
- Asset Preview now includes P0/P1/P2 filters and missing-override diagnostics.
- Added production priority registry and new stable UI/model slots for regional modules/harbor modules.
- Static validation only. Native Godot 4.7.2 device/runtime QA remains required.
