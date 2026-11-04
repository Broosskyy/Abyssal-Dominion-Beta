# M47 — PL6–15 Runtime + Payload/Support Combat

- World grid expanded to 4x4 and now contains reachable map levels through 15.
- PL6–15 regional contracts are read at runtime and tag spawned islands, harbors and NPCs with stable Production slots.
- Missing final GLBs still fall back to procedural world/ship construction.
- Post-beginner progression advances by defeating the Admiral/Boss of the currently unlocked map level.
- Main progression fleet unlock checks run on map advancement/sector build. Starter ships remain a separate 3-ship phase.
- Separate Harpoon Payload runtime selection: Hunter Standard, Barbed Chain and Abyss Piercer.
- Separate Support Ammo runtime selection/fire path: Restoration Shell, Ward Shell and Event Restoration Shell.
- Support fire uses friendly range/reload/stock rules and never uses broadside-angle damage.
- Production QA scenes now contain visible reference geometry/camera/light instead of empty nodes.
- No live MMO/server-authority claim.
- Static source validation only; native Godot 4.7.2 Android/iOS/Desktop QA remains required.
