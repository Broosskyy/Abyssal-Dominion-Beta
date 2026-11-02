# M148 — P1 Regional Asset Batch

M148 prepares the first W2/P1 swap batch for Crimson Sea (PL6–10) and Drowned Reach (PL11–15). Twenty-four uniquely addressed GLB placeholders now cover the two regional NPC fleets, their Admirals, early regional monsters, first instanced flora/coast modules and the Redhaven/Mourning Port harbor shells.

These files are replacement targets, not final art and not live activation. Existing gameplay wrappers retain collision, AI, damage, progression and server-authoritative state. Island modules do not bake water, reef or foam; Godot remains responsible for motion, light, smoke, wakes, foam, trails, impacts and magic.

Canonical Master V3.7 identities and legacy runtime IDs are connected by `data/m148_p1_regional_asset_batch.json`. Asset lookup accepts either identity, so an artist can replace one stable file without changing gameplay code.

The visual acceptance basis remains oblique top-down mobile gameplay zoom. Desktop/macOS may select higher quality, while mobile may reduce instanced dressing first.
