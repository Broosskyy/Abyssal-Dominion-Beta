# M35 — Encounter Relation UI + Guild Contract Foundation

## Grundlage

Fortsetzung des M34-Source-Standes. M35 hält sich an die Guild Bible: In M34-M35 werden nur Daten-, Socket- und World-Contracts vorbereitet. Es entsteht ausdrücklich kein lokales Fake-MMO-Backend.

## Änderungen

- Beginner-NPCs auf Kartenlevel 1-5 erhalten nun einen eigenen Präsentationsstatus: `NEUTRAL`, solange sie nicht provoziert wurden.
- Neutralstatus wird im Target-Panel und an World-Nameplates sichtbar. Neutral nutzt eine türkis/grüne Darstellung statt feindlichem Rot.
- Nach einem tatsächlichen Spielerangriff setzt die vorhandene AI `provoked=true`; die Präsentation wechselt dadurch automatisch zu `HOSTILE`, ohne Targeting-/Combatlogik zu duplizieren.
- Neues `EncounterRelation`-Contract trennt reine HUD-Präsentation von Combat-/Reward-Rechten.
- `guild_contracts.json` bildet die in der Bible vorgesehenen Guild-Datentypen, Rollen und Permission-Keys als datengetriebenen Contract ab.
- `GuildContracts` validiert diese Contracts, persistiert aber ausdrücklich keine Membership-, Treasury-, Diplomacy-, War- oder Ownership-Daten.
- `guild_island_visual_slots.json` bereitet zwölf modulare Visual-/Socket-Slots vor: Island Base, Harbor, Guild Hall, Warehouse, Repair Station, Walls, Cannon/Mortar/Chain/Guardian Tower sowie Decoration- und Event-Layer.
- Guild-Island-Ownership-Persistenz ist im Contract ausdrücklich `false`.
- Aktive sichtbare Build-Bezeichnungen wurden auf M35 / Version 0.35.0 angehoben.
- Neuer M35 Contract-Test ergänzt.

## Grenzen

- Kein Guild Join/Create Flow.
- Keine Treasury/Vault-Transaktionen.
- Keine Alliance-Diplomatie.
- Keine Guild-Island-Ownership oder Facility-Upgrades.
- Kein Siege/Guild War/Rating.
- Kein Serverbackend wird simuliert.
- Kein nativer Godot-4.7.2-Lauf in dieser Umgebung verfügbar; M35 wurde daher statisch/strukturell geprüft.
