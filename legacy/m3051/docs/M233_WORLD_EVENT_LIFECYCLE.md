# M233 — World Event Lifecycle & Objective Continuity

M233 adds a presentation-only lifecycle bridge around the existing `EventRuntime`. The client can ingest a server/admin lifecycle snapshot (`scheduled`, `warning`, `live`, `finale`, `ended`) without locally deciding event time. When no authoritative snapshot exists, the current prototype can only read active/inactive state and recognize the configured final phase as a finale. It does not invent dates or use device wall-clock time to start or stop live content.

Start, prewarning, finale and end transitions produce short HUD feedback. Existing event-owned world nodes are stamped as presentation objectives for the current event phase and reuse the existing world-marker/full-sea-chart/navigation systems. Event bosses/admirals remain existing nodes only. No HUD code advances phases, spawns actors, completes events, grants rewards or changes combat/navigation authority.

For an online build, the server remains authoritative for `event_id`, lifecycle state, start/end timestamps and remaining-time values. The client consumes that snapshot as a replica and presents it consistently on mobile, web and desktop.
