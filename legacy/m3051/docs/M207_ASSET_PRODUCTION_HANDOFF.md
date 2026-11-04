# M207 — Asset Production Handoff

## Produktion jetzt starten
Das Masterkonzept priorisiert zuerst die drei Starter-Schiffe, danach die zusammenhängende Hauptdesignreihe, parallel priorisierte Inselbasen und anschließend Monster-/Loot-/World-Props. Für UI/Combat sollten zuerst die oft sichtbaren Quickslot- und Ausrüstungsicons finalisiert werden.

### 2D zuerst
Empfohlene erste Produktionswelle: Cannon Ammo, Harpoon/Payload, Action Items, Cannon Families, Decks/Equipment und die wichtigsten HUD-/Navigation-Symbole. Ziel ist eine klar erkennbare maritime Dark-Fantasy-Sprache mit Navy/Gold, eigenständigen Silhouetten und guter Lesbarkeit in kleinen Quickslots. Keine reine Recolor-Serie.

### Schiffe
Finale Schiffsreferenzen sollen Front/Side/Top/Rear zeigen, neutral und unbeschädigt, ohne Wasser, Rauch, Feuer oder temporäre VFX. Ein Schiffslevel bedeutet nicht ein neues GLB. Early-/Midgame-Schiffe werden überwiegend als vollständige eigenständige GLBs behandelt; High-End/Prestige kann gezielt modulare Waffen, Segel, Figureheads oder andere sichtbare Module nutzen. Godot übernimmt Damage/VFX/Materialzustände.

### Inseln
Inseln werden ohne eingebautes Wasser produziert. Gelände/Unterbau und ggf. statische Hauptarchitektur bilden den Basis-GLB; Vegetation, Reefs, Hafenmodule, Landmarken und VFX können modular ergänzt werden. Küstenschaum, Wasser, Nebel und dynamische Effekte bleiben Godot-seitig.

### Technischer Handoff
Jedes finale Asset ersetzt einen stabilen Slot. Collision, Navigation, Muzzle-/Hardpoint-, Nameplate-, Selection- und Damage-/VFX-Anker bleiben technische Verträge. Finales Art darf diese Gameplay-Verträge nicht still verändern. `data/m207_asset_production_queue.json` enthält die aktuelle Reihenfolge und Handoff-Checkliste.

## M207 neue visuelle Zwischenstufe
Zusätzlich zu den bereits sichtbaren Decks unter dem Schiff zeigt der lokale Placeholder jetzt repräsentative Hull-Armor-Bänder, Cannon-Battery-Module, Sail/Rigging-Verstärkung, Harpoon Rack und bei hohem Hull-Ausbau eine Bugramme. Diese Elemente sind **visual_only** und keine Treffer-, Collision- oder Projektilautorität. Sie dienen als Brücke, bis finale Schiff-GLBs bzw. modulare Hero-Assets vorliegen.
