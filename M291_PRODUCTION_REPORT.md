# M291 Production Report

M291 hardens the first sea-sortie observation path without changing movement, combat, rewards or ship construction. A water-tap intent now observes only Tap-to-Sail; leaving the Haven's Reach interaction or physically exiting its proximity observes departure. Harbor return requires an actual dock event after departure, not an artificial defeat/respawn. Cannon presentation is scoped to ship targets and harpoon presentation to monster targets; neither proves a hit. Rejected local M289 observations no longer leave behind a misleading M290 progress record.

The regular journey is ten core observations; defeat/respawn remain two optional, separately recorded QA cases. Progress is labelled as observed, never as server-certified or native QA PASS. Existing complete individual ship GLB placeholders and the external replaceable M290 beacon are reused, with no modular hull/mast/sail construction.

Native Godot 4.7.2 parsing, desktop/Android gameplay, GPU, audio, haptics and full first-sortie evidence are still NOT_EVALUATED. Seafight/Battle of Sea are clean-room feel/readability references only.

Validation: 451/451 zero-argument static/integration checks, 17/17 unittest checks, 468/468 combined checks, 564/564 JSON files. No native Godot binary is available in this runtime; parser/device results are not claimed.
