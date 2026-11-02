# M51 — Ship Mastery + 50-Design Progression UI

- Added a dedicated mobile-first ShipMasteryPanel covering the 3 starter ships and all 50 reserved main progression designs.
- Every playable design keeps its own level 1–10 mastery record and its own XP.
- Existing runtime scaling of +2% Hull and +2% Damage per ship level after level 1 is now explicitly described in ship_mastery.json rather than silently changing balance.
- Mastery XP thresholds are centralized in ShipMasteryCatalog and PlayerShipRoster no longer hardcodes the curve.
- Level-up emits a mastery signal, HUD notification and visual-only `mastery_level_up` VFX hook.
- Added harbor-only equip action from the mastery browser.
- Added 53 stable ship-card slots, 10 stable mastery-badge slots and one mastery level-up VFX slot.
- Generic original card art is the fallback for all ship cards until individual final card art/renders exist.
- Production coverage now contains 275 slots. Missing final overrides: P0 142, P1 124, P2 9.
- No live/server reward authority is claimed.
- Static validation only; native Godot 4.7.2/device QA remains required.
