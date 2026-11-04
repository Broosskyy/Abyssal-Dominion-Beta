# M46 — PL6–15 Content Foundation + Production Integration

- Preserves the canonical 3 starter ships and reserves the separate 50-design main progression fleet.
- Main progression IDs ship_main_01..ship_main_50 now have data contracts, 10 mastery levels each, stable visual slots and procedural fallback profiles.
- PL6–15 foundation activates the first five progression-design unlock entries without claiming final GLBs.
- Added three regional placeholder contracts for levels 6–15 with NPC, island, harbor and boss slots.
- Added separate Harpoon Payload and Support Ammo catalogs. These do not collapse into cannon ammunition.
- Prepared stable UI slots for payload/support icons.
- Added five concrete QA scene entry points for Production Masterlist positions 698–707 plus the existing replacement/preview pipeline.
- All new production content remains replaceable. Missing final assets must not break gameplay.
- No fake backend/server authority.
- Static validation only; native Godot 4.7.2 QA is still required.
