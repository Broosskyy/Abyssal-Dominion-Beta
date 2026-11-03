# Device footage review: live harbor and readable NPC state

The supplied phone screenshot and videos 206839.mp4 (46.91 seconds) and 206846.mp4 (50.27 seconds) show the data-30 HUD and neutral entry NPCs running on Android. They also show the harbor upgrade flow, moored state after closing its window, changing zoom and combat. This confirms those visible flows, not every Android updater/background/failure scenario.

Two behavior defects were confirmed against source: docking returned before the world clock/NPC updates, freezing the entire local sea; menu scroll position survived closed-window reopens and navigation to another menu. The next data release keeps NPC patrols and respawns advancing while the moored captain cannot move or be attacked, including in hostile regions. Menus reopen at the beginning, while a purchase refresh of the currently visible menu retains its scroll position.

Neutral ships now use amber markers and health bars, hostile/retaliating NPCs use red, monsters remain distinguishable on the minimap, and the selected minimap target has a small outline. The target card follows the same neutral/hostile health colors. The clipped cannon icon was removed from the narrow weapons button. Docked status explicitly says to depart, and harbor copy reflects a moving sea rather than a paused simulation.

Existing source ship views, source resolution and atlas artwork are unchanged. Low-resolution four-view NPC art still differs visibly from the newer eight-view starter, especially at close zoom. These corrections do not claim new NPC perspectives or replacement artwork. Further fleet art and UI direction remain active work.

Validation includes moored-captain protection with moving patrols in all three regions, exact diagonal motion, neutral proximity/selection and retaliation, menu reopen/reset/purchase-scroll behavior, and the existing simulation, progression, rendering and signed resource-pack checks. Renderer evidence adds a live-harbor image, menu-top image and a measured patrol-distance receipt. No bootstrap/native files are changed, so distribution remains data-only for shell 305901.
