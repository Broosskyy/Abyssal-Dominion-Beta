# M297 Production Report

The remaining early Scout and Heavy NPCs now use individually replaceable complete GLB placeholders. Their prior structural silhouette details (Scout raised bow/stern and bowsprit; Heavy raised decks and gunwales) are baked into one mesh per ship. M295 Raider and M296 coastal sloop/gunship remain separate complete models. All five active early NPC asset slots now have unique GLB bytes and skip runtime structural ship-part decoration on these exact paths; legacy fallback assets remain unchanged.

This is a visual placeholder step, not finished authored ship art. The same stable asset IDs remain available for later no-code asset replacement. No collision shape, ship motor, Tap-to-Sail input, combat authority, NPC AI, economy or reward data changes. Seafight and Battle of Sea are clean-room UX/genre references only. Godot native import, desktop/Android gameplay silhouette, GPU and LOD QA remain NOT_EVALUATED.

Validation: 446/446 static regression/contract functions and 17/17 unittest cases passed (463/463 checks); 570/570 JSON files parsed. The two M297 GLBs reproduced documented hashes and passed structural/accessor/triangle checks. Native Godot and visual playtesting were not available.
