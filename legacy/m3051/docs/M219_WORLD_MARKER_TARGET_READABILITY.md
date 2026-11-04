# M219 — World Marker, Target & Loot Readability

M219 is a presentation/readability pass for the high/wide gameplay camera locked by M213/M214 and the five gameplay master references.

The priority order is tracked objective → selected target → boss/admiral → high-tier loot → mission threat → nearby loot → ambient POI → non-selected common enemy. Selected targets gain a stronger nameplate/range read and minimap ring. Common enemies stay compact so the sea-chart center remains usable. Loot marker priority now reflects tier without changing rewards or pickup authority.

Permanent HUD safe zones and nameplate/marker collision avoidance remain authoritative. Mobile, web and desktop use identical world/target/priority semantics; responsive sizing/density budgets are the only allowed presentation difference. No combat, movement, collision, reward, range or pickup-radius balance values are changed.
