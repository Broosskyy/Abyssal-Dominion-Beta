# M160 — Data-driven System Depth Foundation

M160 corrects the generic M159 special-deck placeholders and establishes a clean-room, genre-inspired content architecture for normal decks 1–10, six distinct special decks, cannon upgrade tracks, ammunition families, five talent trees, six citadel branches, guild content types, buffs/VFX and mobile interface/icon contracts.

## No-code rule
Game content is represented as data/content records. Admin content types now include special decks, talent trees/nodes, citadel branches, cannon upgrade tracks, buffs, guild buildings and guild towers. Draft/validation/review/version/publish authority continues through the existing AdminContentRegistry/ContentAdminGateway boundary; production mutation is not faked locally.

## M159 correction
The generic motor/armor/cannon/crew/harpoon deck list is retained only as deprecated migration data. It is not the canonical M160 special-deck design.

## Next production wave
Wire full player-owned progression/save state, detailed panels and icon asset slots; implement talent/citadel effects through declarative behavior components; deepen guild ranks/treasury/island siege; expand ammunition/harpoon/item catalog and VFX; continue old-content audit.
