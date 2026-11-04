# M237 — Event history, placements and reward receipts

M237 extends the M235/M236 server-replica event model with a separate read-only history snapshot. It is intended for recurring events and seasons so a completed event is not visually treated as if the player had never participated.

The server remains authoritative for completion, personal/group placement, contribution, qualified tier, settlement and reward delivery. The Godot client only accepts a monotonic replica and renders it. Missing history never creates simulated past events, ranks or receipts.

A history row may contain the event/season identity, completion timestamp, contribution, personal/group rank, qualified tier and settlement reference. Reward receipts require a receipt id and can expose a server-signature-present flag. The client cannot manufacture or mark a receipt delivered.

This milestone does not change combat, event reward values, current event progression, world navigation, camera composition, minimap or sea-chart rules.
