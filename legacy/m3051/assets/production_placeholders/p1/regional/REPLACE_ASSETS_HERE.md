# M148 P1 Regional Swap Folder

Replace the uniquely named GLB files in place. Keep filenames and canonical slot mappings stable.

- `ships/`: Crimson Sea and Drowned Reach NPCs/Admirals
- `monsters/`: early and regional hunter/monster silhouettes
- `nature/`: instanced flora with mobile-friendly LODs
- `islands/`: coast/land modules without baked water, reef or foam
- `harbors/`: Redhaven and Mourning Port geometry shells

GLBs contain visual geometry only. Gameplay collision, AI, damage, progression and server state remain outside the files. Godot supplies movement, lighting, smoke, wakes, foam, trails, impacts and magic.
