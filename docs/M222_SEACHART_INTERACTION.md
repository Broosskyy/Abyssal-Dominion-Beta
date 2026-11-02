# M222 — Sea-chart interaction lock

M222 locks the normal gameplay minimap as **round** and the expanded/full sea chart as **rectangular/full-screen**. This preserves the compact nautical HUD read from the five gameplay master references while giving planning/navigation a larger precise surface.

Target actions share one vocabulary: track/untrack for quest authority, select target for combat authority, and navigate for an already-resolved world node. Navigation never fabricates a destination and continues to delegate movement to PlayerShipInput/M192 island avoidance.

Mobile, web and desktop use the same world targets and navigation state. Only responsive UI dimensions/touch targets differ. No damage, range, speed, reward, collision, spawn or route-balance values change.
