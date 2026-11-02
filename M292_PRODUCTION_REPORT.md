# M292 Production Report

M292 makes first-sea-sortie guidance visible in the existing mission panel. When the player has not selected a quest, that panel shows the next observed-stage label, hint, and progress. An actively tracked quest retains full priority; only a short sortie count is displayed when the panel has adequate width. On narrower layouts, the secondary badge disappears. The center sea chart, primary attack cluster, camera-only joystick, and one existing replaceable world beacon remain unchanged.

The read model exposes distinct counts for local-development and server-verified observations. The Command Deck shows those counts and separate optional defeat/respawn QA; a local input or cosmetic fire effect never claims successful travel, impact, healing, a native QA PASS, or a release approval. The initial ship-asset rule remains one complete individual GLB per ship; the existing replaceable placeholders are reused, not cut into interchangeable modules.

Native Godot parser, desktop/Android gameplay, GPU, audio and haptics remain NOT_EVALUATED until actual device evidence exists. Seafight and Battle of Sea remain clean-room genre/UX references only.

Validation: 454/454 zero-argument regression/integration checks, 17/17 unittest cases, 471/471 combined automated checks, 565/565 valid JSON files. Godot is not installed here, so parser/device gates are not asserted as passing.
