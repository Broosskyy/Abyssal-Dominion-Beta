# M3065 — status and deck fittings from the supplied close-up

This replaces the small circular deck markers of data 52. The new current/reference pair (1793899850845.jpeg and 207252.jpg) makes the intended silhouette explicit: square enamel deck fields, a pirate crest above, and metal fittings on either side. The product still has ten regular slots in two rows of five, even though the particular reference close-up shows a different occupied grid.

The captain block is now name, separate HP number, straight green HP gauge, straight blue shield gauge, then the deck assembly. HP/shield width is 132 logical pixels; the metal assembly spans approximately 146 pixels. Name size is 16, HP number 11; both retain zoom-independent screen size and the fixed waterline anchor. The reserved caption block includes the broader assembly. Neighboring hulls cannot push it around.

Regular deck materials retain their game meanings: gold orange/yellow, elite blue, crystal purple. Empty slots have subdued square seats, with no invented ownership. Original vector bevels and steel fittings replace round ability discs. Tide, storm, salvage and blessing use separate inlays on four fittings: inactive means bare steel, active means the respective coloured wave, lightning, gold or crystal detail. Their timers and effects remain simulation-owned and unchanged. The pirate crest is decorative, not an extra purchased slot.

The shared deck assembly is used below the captain and in the ship/deck windows. There are no changes to ammunition, purchasing, saves, combat or the updater bootstrap in this pass.

Verification: native renderer captures include two owned gold decks, all ten mixed-material decks, and ten elite decks, plus 1536x709 and 844x390 views. Existing caption crossing, layout, ammunition and deck progression suites pass locally in Godot 4.6.3. Release CI repeats the checks and native captures under the required Godot 4.7.2 before publication.
