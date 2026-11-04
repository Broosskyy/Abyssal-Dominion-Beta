# M220 · Navigation & World Guidance

M220 makes the existing Tap-to-Sail/navigation foundation readable at the M213/M214 zoomed-out master-reference camera. It is a presentation and usability milestone, not a balance or movement rewrite.

The captain's final water/world destination remains authoritative. The HUD may now expose the current local steering bend produced by the existing M192 island-avoidance logic, but it does not create a waypoint chain or new pathfinding authority. A visible final target receives one compact ring and distance/intent read; an off-screen destination receives one prioritized edge cue rather than breadcrumb spam.

Tracked quest navigation still resolves only to world nodes that actually exist in the current sector. The Command Deck track/untrack and "AUF SEEKARTE ANSTEUERN" flow therefore cannot fabricate targets. Recenter only clears camera pan and leaves zoom, target selection and active sailing destination intact.

All navigation/world semantics remain identical on mobile, web and desktop. Responsive differences remain limited to presentation scale, spacing, safe areas and touch affordances.
