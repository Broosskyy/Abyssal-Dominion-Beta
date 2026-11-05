# M3064 — ammunition selection and point decks

This supersedes the permanent special-ammunition buttons and regular diamond deck markers from M3063. It implements the supplied Battle of Sea / Seafight screenshot layout in the existing game.

## Ship status

Fixed order below the ship: captain name, HP, shield, ten regular deck points in two rows of five. Gold is orange/yellow, Elite blue, Kristall purple; empty slots are subdued. Material is separate from the existing deck equipment role. Tide and other special-deck symbols surround the point rows. The fixed waterline anchor and captain priority from M3063 remain, including suppression of conflicting nearby NPC captions; labels do not repel one another.

## Ammunition

One MUNITION button displays the selected type and real stock. Tap opens a plain dark scrollable list; tapping a complete row selects it and closes the list. Reopening highlights and scrolls toward the selected entry. All seven existing types share this list, including the four special types. Their permanent action buttons and the 1/2 page selector are removed. Four supplies remain separate actions.

Selecting ammunition consumes neither stock nor gold, preserves reload timing, persists the selection, and cannot leak the closing touch into sailing. Empty stock remains visible as zero. Special ammunition still consumes one round per shot; normal cannon/chain consumes three. Special-ammunition purchases remain available in the harbor.

## Rendering

The shared font uses MSDF before text rendering, reducing blur at scaled HUD sizes. Source PNG pixels remain unchanged; the build prepares mipmaps after the first import and reimports before tests/export. World textures use linear mipmap filtering, while HUD imagery uses linear filtering. Text outlines and orb rims are reduced. Existing low-resolution NPC source frames still limit ship detail and need separate replacement; this change does not claim new high-resolution fleet artwork.

## Verification

The supplied 32.66-second current-state video and current/reference screenshots were reviewed. Native OpenGL captures cover ammunition at 720x405, 844x390, 1280x720 and 1560x720, and material-point decks at 1536x709 and 844x390. Local Godot 4.6.3 verifies UI, selection, actual firing, persistence, popup bounds, scalable font and imported mipmaps. The release workflow repeats the suites and captures with required Godot 4.7.2 and verifies the signed content pack.
