# M95 — Halloween Combat Encounters + Admin QA

M95 converts the Halloween fleet from visual-only ships into local combat encounters using the existing canonical ShipHealth, ShipWeapons and EnemyShipAI stack.

- Five Halloween encounter definitions: Drowned Deckhand, Gravewake Raider, Admiral Hollow-Eye, Lantern Maw and The Drowned Sovereign.
- Event ships are normal targetable enemies and preserve the project's no-broadside-angle-damage rule.
- The Halloween world layer still caps the event fleet at three simultaneous phase entities.
- Event sink progress and harpoon-vs-event-monster progress now feed EventRuntime.
- Local quest completion grants preview Drowned Embers and score; this is explicitly not live/server reward authority.
- Admin overlay can spawn all five encounter roles, add event score, toggle event/phase, teleport and use the existing test controls.
- Admin overlay now reads display safe area and adjusts compact height.
- Marker-priority, VFX and asset-browser contracts/slots were added for the next runtime polish pass.
- Master P0 first-13 final-art priority remains unchanged.
