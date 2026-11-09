# Browser fullscreen and sprite alignment

The browser shell offers a fullscreen start and a windowed alternative. Downloading starts immediately and shows real byte/progress feedback. A persistent 44px fullscreen control supports re-entry after exiting. Landscape locking is attempted only after the user's fullscreen gesture and degrades gracefully when unsupported. Download failures expose a retry action.

Browser fleet atlases now retain per-view alpha bounds, a projected water-contact pivot, and a shared source-length scale. Cropping does not stretch headings independently. Captain/NPC captions use a stable maximum hull bottom so turning cannot move the caption up and down. Monster baselines come from visible sprite alpha bounds. Browser HUD and captions get a modest readability increase; native presentation is unchanged.

Vercel waits for the browser release matching a game-changing source commit before publishing it. This avoids reporting a new commit while serving the previous test ZIP.

Validation: Godot 4.7.2 rendered all 23 atlases / 184 headings. Browser geometry tests cover 718 checks including source-scale consistency, water pivots, caption clearance at three zoom levels and heading stability. The existing UI regression suite passes 2,054 checks. `tests/browser_capture.gd` captures desktop and mobile landscape views using the actual 2D fleet. Browser CI also exercises the HTML shell's real fullscreen entry/exit, progress, windowed mode, denied fullscreen recovery and download failure using Chromium. Physical Android fullscreen/orientation support still depends on the browser.
