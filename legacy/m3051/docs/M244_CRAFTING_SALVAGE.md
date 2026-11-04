# M244 — Crafting & Salvage Convergence

M244 closes the local V3.8 Crafting/Salvage gameplay slice without pretending that the online economy backend exists.

## Master alignment
V3.8 defines CraftRecipeDefinition (`inputs`, `outputs`, `station`, `requirements`), upgrade costs in Gold/materials without destructive normal failure, and SalvageDefinition (`input`, `returns`). Unneeded equipment may return only part of its material class; bound/special items require their own rules; salvage may never create a duplication loop.

## Runtime changes
Existing M165 recipes now pass through an M244 transaction preflight. The local prototype snapshots inventory/coins, consumes recipe inputs, applies Gold cost and output, and rolls back if a commit step fails. This is local safety only; production online crafting must be an atomic/idempotent server transaction.

Regional equipment modules are the first actual equipment salvage surface. Salvage requires harbor access, ownership, no active equip on any ship, an allowed binding rule, valid return materials and free output capacity. The owned module is removed and only a partial material return is granted. No Gold is refunded. The 50% return is explicitly prototype balance, not a final V3.8 value.

## UI
Command Deck > Ausrüstung & Ausbau > Werkstatt now exposes the canonical crafting categories and a separate Salvage section with the exact return preview or a blocking reason before action. The normal sea-map HUD is unchanged.

## Authority
The client cannot be treated as authoritative for production crafting, salvage, inventory ownership or economy ledger mutation. Connected online services remain required.
