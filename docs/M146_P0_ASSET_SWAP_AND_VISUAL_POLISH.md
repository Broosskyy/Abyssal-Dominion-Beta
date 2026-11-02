# M146 P0 Asset Swap and Visual Polish

M146 follows the V3.7 production order and closes the first practical asset-production handoff for the PL1-5 vertical slice.

## Dedicated GLB slots

Fourteen P0 elements now have individual files under `assets/production_placeholders/p0/`: three starter ships, five early NPC ships, Haven's Reach, four deliberately different island silhouettes and the first monster. Replacing one file no longer changes another slot that previously shared the same fallback GLB.

The filenames are stable. A final Rodin/Meshy or artist-made GLB can overwrite the matching file without changing gameplay code, content IDs, admin records or scenes. Collision, movement, weapons, sockets, health, selection and input remain wrapper-owned.

## Visual polish

The runtime applies platform-aware LOD, shadow, visibility and VFX-density metadata after slot-specific silhouette decoration. Desktop retains the highest profile, Android/iOS use a mobile budget, and Web preview uses the lightest profile. The system never changes gameplay geometry.

## Production gate

The P1 PL6-15 wave starts only after P0 files pass orientation, waterline, bounds, material, gameplay-zoom readability, anchor and device QA. Placeholder availability is not a claim that final art is complete.
