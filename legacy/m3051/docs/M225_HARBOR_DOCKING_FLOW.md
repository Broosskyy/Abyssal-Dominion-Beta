# M225 — Harbor docking flow

M225 turns the existing harbor proximity interaction into a clear three-state flow: at sea, harbor approach, and docked. The same contextual interaction docks or leaves the harbor. Docking still records the existing dock visit, sets the respawn point, stops the ship, saves state, and exposes existing local services; leaving only clears the local docked state and returns control to sea gameplay.

A compact docked-harbor HUD strip keeps the 3D world visible and the gameplay center clear. It exposes Werft, Reparatur, Markt and Arsenal as the primary harbor service language without duplicating their existing system authorities. Global shipyard/equipment/meta access remains global according to the M187/M188 boundary; M225 does not convert those systems into harbor-only features.

No damage, range, reload, movement speed, collision, navigation routing, spawn, reward or economy values are changed.
