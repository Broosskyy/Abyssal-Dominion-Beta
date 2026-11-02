# M226 — Harbor world readability and services

M226 deepens the M225 docking flow without turning the harbor into a separate gameplay scene. The existing pier remains collision authority; visual-only twin approach beacons, a lane read and a mooring cue make the dock easier to read from the M213/M214 master-reference camera.

The compact docked strip now exposes real hit targets for Werft, Reparatur, Markt, Arsenal and Ablegen. Each action delegates to the existing authority. Repair uses the existing harbor quote/purchase method and therefore does not alter economy values. Success, no-damage and insufficient-gold cases receive explicit feedback.

Mobile, Web and Desktop use the same world and service semantics. Only responsive HUD sizing differs. Native Godot/device visual QA is still required.
