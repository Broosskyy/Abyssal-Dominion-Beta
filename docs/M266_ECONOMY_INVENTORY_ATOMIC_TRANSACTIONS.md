# M266 — Economy / Inventory Atomic Transactions

M266 joins wallet, inventory, loot, shop, crafting, salvage, Bazaar and equipment mutations behind one fail-closed server transaction boundary. Client code only prepares intents. Durable value movement requires revision guards, idempotency, server-owned locks, atomic commit/abort and a server receipt. No final limits, retry counts, lock TTLs, capacity values or economy balance numbers are invented.
