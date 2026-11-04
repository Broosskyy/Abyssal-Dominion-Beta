# M207 — Masterkonzept V3.8 Source Audit

## Basis
Geprüft wurde der aktuelle Game-Source-Stand gegen das hochgeladene **ABYSSAL DOMINION Masterkonzept V3.8** und die vorhandenen visuellen Masterreferenzen. Der Audit bewertet ausschließlich, was im Game-Source statisch nachweisbar ist. Native Godot-, Android- und Desktop-Sichtprüfung ist weiterhin offen. Backend, Database, Admin/CMS und Web/Support werden nur als Master-Scope erfasst und nicht als fertig behauptet.

## Was bereits belastbar vorbereitet ist
Die Seekarte ist als Kernloop vorhanden, Tap-/Click-to-Sail und Camera-only-Steuerung sind getrennt, Target-Combat, Kanonen, Harpunen, Munition, Action-Items, Loot, Decks, Schiffs-Mastery, regionale Encounter, Häfen und mehrere Meta-Systeme besitzen bereits Daten-/Runtime-Foundations. Mobile/Web/Desktop sind in Welt und Gameplay auf denselben Inhalt gelockt; responsive Unterschiede bleiben UI-Größe, Touchflächen, Abstände und Safe Areas.

Die Asset-Architektur entspricht der im Master geforderten Richtung: stabile Visual Slots, Placeholder/Fallbacks und austauschbare Pfade. M203–M207 haben die 2D-Placeholder-Struktur für Munition, Items, Kanonen, Decks, Harpunen und Schiffsausrüstung ausgebaut. Schiffs-/Insel-/Loot-Placeholder sind vorhanden, ersetzen aber noch keine finale Art-Produktion.

## Größte aktuelle Lücken zum Master
1. **Finale Art** ist jetzt der größte sichtbare Gap: Starter-/Progressionsschiffe, Inseln/Häfen, NPCs, Monster, Loot/World Props sowie finale HUD-/Item-/Weapon-Icons.
2. **Native Visual QA** fehlt weiterhin. Kamera, Wasser, Küsten, Maßstab, Menüüberlagerungen, Touchflächen und Combat-Feedback müssen in Godot auf realen Zielgrößen abgenommen werden.
3. **HUD/Menu-Konvergenz** ist funktional weit, aber noch nicht final auf Masterreferenz-Niveau. Die Seekarte muss dominant bleiben; keine persistente untere Karten-/Command-Bar und kein zentrierter Hauptangriff.
4. **Online-Autorität** ist im lokalen Source nur vorbereitet. Master-Anforderungen zu Backend, DB, serverautoritativem Combat/Economy, Admin/LiveOps, GLOBAL/TEST, Support und Webplattform sind nicht als produktionsfertig anzusehen.
5. **Content-Tiefe** bei Bonusmaps, Events, Gilden, Basar, Companion/Artifact/AFK und High-End-Systemen ist teilweise Foundation/Architecture und noch nicht vollständiger Live-Service-Content.

## M207-Konsequenz
Ab M207 sollte die Source-Arbeit zweigleisig laufen: sichtbare Gameplay-/HUD-/World-Optimierung weiterführen und gleichzeitig finale Assets systematisch über bestehende Slots ersetzen. Das verhindert, dass später finale 2D-/3D-Art erneut Codeumbauten erzwingt.

Die maschinenlesbare Matrix liegt in `data/m207_master_concept_source_audit.json`.
