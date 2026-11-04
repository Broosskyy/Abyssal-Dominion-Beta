# M214 — Master-reference world scale & composition

M214 is the implemented follow-up to M213. It locks the visible scale hierarchy against the five gameplay master references: player/selected target first, landmark harbor/island second, encounters next, then medium islands/navigation punctuation and loot/POIs. The M213 wide oblique camera is preserved.

A new `M214WorldScaleCatalog` defines visual-only ship, island and monster scale classes. Procedural ships and islands are annotated at creation time so authored replacements can inherit the same hierarchy without coupling art scale to collision, range, damage or navigation. Harbor islands remain world anchors and loot keeps the M200 visual-only beacon.

This milestone does not claim native visual approval. Godot/Android/Desktop visual QA is still required once the runtime is available.
