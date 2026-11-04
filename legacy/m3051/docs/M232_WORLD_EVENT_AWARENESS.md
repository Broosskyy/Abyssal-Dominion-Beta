# M232 — World Event Awareness

M232 connects the already-existing `EventRuntime` and event-owned world nodes to restrained gameplay presentation. The HUD may now announce entering/leaving an active event footprint, phase changes, and nearby event bosses/admirals. It does not create, schedule, advance, reward or resolve events.

The active `EventRuntime` remains the only local prototype event authority. M232 reads its event id/title/phase/meter and finds only world nodes carrying the same `event_id`. Awareness radii are presentation thresholds only. They never become aggro, weapon, collision, navigation, spawn or reward ranges.

The normal round gameplay minimap, rectangular full sea chart, M213/M214 camera and M231 encounter-zone feedback remain unchanged. Feedback is short-lived and placed in the upper world-safe area so the sea remains dominant.
