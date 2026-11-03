# M3058 — user recordings 206805, 206806 and 206807

Reviewed 3 November 2026. The three supplied recordings are 2340×1080 at 60 fps, with durations approximately 52.19 s, 64.37 s and 59.42 s. Full-clip overview frames were sampled every two seconds, with full-resolution inspections of the marked intervals. This does not imply every encoded frame was inspected.

| Recording / time | Observation | Source correlation / change |
| --- | --- | --- |
| 206805, 17–31 s; clear at 20 s | A large opaque chest tile appears underneath the captain at the Nordmeer portal. Region name and captain name overlap. | sea_map draws icons.portal as a 96×96 world texture. Replace that presentation with transparent, perspective-aligned chart rings. Nearby live actors suppress the redundant world caption; the existing contextual portal action remains available. |
| 206805, 19–25 s; 206806, 55–63 s | Several −31/−23 numbers overlap almost exactly above a hull. | Three cannonballs arrive 0.08 s apart; every impact used the same floating-label baseline. Group display totals for one target within 0.28 s and separate independent volleys vertically. Damage events, ammo consumption and hit effects remain unchanged. |
| 206807, 27–39 s | Harbor text and equipment reach into the lower decorative frame while scrolling. | The desktop-style panel also appears on the phone because project canvas stretch keeps a 720-high logical viewport. Inset the decorated scroll area 76 px left / 160 px top / 78 px bottom; keep the existing compact flat panel layout. |
| 206806, 55–63 s; 206807, early combat then drydock | Low HP uses torn sails; repaired hull uses intact sails. | Observed behavior is consistent with the current 35% HP threshold. These clips do not establish random intact/damaged switching at full HP. |
| Across all clips | Legacy NPCs look softer and turn more coarsely than the new starter; several old hulls remain low-resolution. | Existing mixed single/four/eight-view asset coverage remains a content limitation. This patch does not invent missing angles, change art resolution or introduce 3D. |

## Verification boundary

Automated regressions cover complete volley totals, independent targets/volleys, expiration without smaller ghost totals, caption clearance and decorated scroll insets. Runtime captures use the actual sea-map renderer with controlled fixture states at the submitted phone resolution and retain the project canvas stretch. They are candidate examples, not pixel-identical replays of the user's uncontrolled recordings. All existing sprite sources and the save file remain unchanged.

The M3058 APK increments Android code to 305801 / version 0.305.8-test.1, keeps the application and signer, and is published through the M3057 updater after build, signature, runtime captures and anonymous download verification. Physical Android revalidation remains pending. Remaining art consistency, finer NPC direction sets, ship collision/separation and camera joystick work are not claimed as completed by this patch.
