# Decks, anchored ship readouts and brighter sea

Baseline: data-50, main `2eb1331d40b148141bf7ec6aa8f20e9282938c2a`.
Acceptance references: supplied current-game screenshots 207199, 207201, 207203,
207205 and the Battle of Sea reference 206873, plus the user's explicit deck rules.
This pass supersedes the previous decision to move the captain's decks to an edge.

## Comparison and resulting changes

| Area | Data-50 | Reference / requested behavior | Implemented |
| --- | --- | --- | --- |
| Ship readout | Thin 72×3 captain HP bar, 12 px title | Readable name and bars stay together under the hull | 15 px captain title, 112×8 HP bar with current HP, 112×5 shield bar; screen scale remains stable when zooming |
| Overlapping ships | Per-frame collision search could move captions far away and draw leader lines | Stable relation between hull, name, HP and decks | Fixed waterline-relative anchor; no repulsion or leader lines. Captions covered by the captain block yield, while target details remain in the edge HUD |
| Normal decks | Two slots, coloured by role, icons at the left edge | Ten slots, two rows of five, below HP/shield | Ten real slots and a fixed two-row badge directly beneath the bars; deck role remains separate from material |
| Materials | Wood / reinforced / war names; role-specific colour | Gold orange/yellow, Elite blue, later Crystal purple | Material indices 0/1/2 retain their effects and become Gold / Elite / Kristall, with explicit material colours |
| Special decks | Tide shown as another row gem or timer | Separate surrounding icons | Original wave, lightning, anchor and crystal symbols around the regular grid; active tide time also lights the outer wave bracket |
| Short phones | Four special-ammo buttons extended across the lower middle | Space for the anchored ship block | Four buttons use a 2×2 grid beside the right combat controls; wide screens keep their existing row |
| Water | Near-black teal | Lighter sea blue, without returning to large wave stripes | Brighter blue/teal base, quiet moving surface and regional tint retained |

The Seafight [official deck FAQ](https://board-en.seafight.com/threads/decks.47455/)
describes distinct surrounding marks for special decks/legacy effects. That is the
structural reference for separate symbols; no Seafight icons, names, prices or
bonuses are copied. The ten-slot arrangement and Gold/Elite/Kristall colour rule
are the user's product specification, not a claim about every current Seafight version.

## Actual progression and migration

- There are ten mounted physical decks, with storage for thirty individual items.
  Purchased copies can share a role; one physical item cannot occupy two slots.
  Kessel duplicate rewards retain their existing conversion to essence.
- Existing role effects are preserved. Gold decks cost the existing 600 gold each.
  An individual deck upgrades to Elite at captain level 3 for 900 gold, then to
  Kristall at level 8 for 1,800 gold and 6 essence. These are initial game values.
- Tide keeps its actual timed +10 cannon slots. The new original Sturmdeck gives
  +12% sailing speed and Bergungsdeck +15% loot gold. Both cost 900 gold for thirty
  minutes from level 3 in the harbor. The fourth surrounding mark represents the
  already implemented Kristallsegen, not an extra regular deck.
- Save schema 4 accepts schemas 1–3, preserving the first two mounted decks, their
  material indices, inventory, progress, wallet and tide duration. The remaining
  eight slots start empty. No eight free decks or fake active special decks are granted.

## Evidence and limits

- `deck_progression_test.gd`: 44 checks for ten slots, purchases, upgrades, tier
  colours, two-row geometry, item uniqueness, save migration and timed effects.
- The presentation suite tests fixed anchors while nearby hulls cross the player,
  all HUD profiles, three zoom levels and four screen sizes. These checks replace
  the earlier requirement to keep every caption separated by repositioning it.
- Actual renderer captures include close encounters, ten mixed-material decks with
  active specials at 1536×709 and 844×390, and the deck yard on the short phone.
- A median RGB sample of the same 100×100 sea patch at (500,350) was (12,30,44) in
  207199, (27,65,126) in reference 206873 and (8,58,92) in the candidate renderer.
  This supports a lighter, bluer surface; it is not a pixel-match claim.
- Local validation uses installed Godot 4.6.3. Publication performs Godot 4.7.2,
  signed-pack boot validation and renderer capture. A physical Android test remains
  separate. Existing NPC source graphics are unchanged.
