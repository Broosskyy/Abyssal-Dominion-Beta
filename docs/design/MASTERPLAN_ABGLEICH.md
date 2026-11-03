# Masterplan Abgleich und Vorgabe für das erste 2D Schiff

Stand 3. November 2026. Die fünf hochgeladenen DOCX und die Referenzanalyse wurden für Schiffsproduktion, Reihenfolge, Visual Bible, HUD und den ersten spielbaren Abschnitt ausgewertet. Dies ist ein Abgleich der relevanten Abschnitte, kein Vollständigkeitsnachweis für alle Systeme des Masterkonzepts.

## Welche Vorgabe aktuell gilt

Die aktuelle Nutzerentscheidung lautet: Zunächst ein solides Spiel mit 2D-Schiffen; 3D kann später schrittweise folgen. Damit sind die GLB-/Rodin-Arbeitsschritte der älteren Produktionsunterlagen für die aktuelle Phase ausgesetzt. Gameplayziele, Starterreihenfolge, stabile IDs, austauschbare Grafiken und HUD-Locks bleiben bestehen.

| Quelle | Relevante Festlegung | Konsequenz |
| --- | --- | --- |
| Asset Production Masterlist V2 | 707 Produktionspositionen; P0 zuerst; drei Starter; Mobile-Kamera ist Abnahmegrundlage | Die Liste ist ein Produktionskatalog, kein Nachweis von 707 fertigen Assets |
| Asset-Erstellungsreihenfolge V1.0, Abschnitte 1, 2 und 6 | Starter Ship Small zuerst vollständig integrieren und prüfen; dann Medium/Large; Fallbacks dürfen Gameplay nicht blockieren | Zuerst ein kleines Referenzschiff; keine High-End-Flotte als Einstieg |
| Schiffsprogression Masterkonzept, Abschnitte 4 und 8 | Starter 01 klein, ein Hauptmast, gealtertes Holz, neutrale Segel, dezente Metallakzente; einfache lesbare Silhouette | Schattenklaue und große Dreimast-Fregatte sind als erstes Starterschiff ungeeignet |
| Masterkonzept V3.8, Punkte 121/122, 523/525/526 und 830 | SHIP-STARTER-001; Start mit Small, Medium/Large innerhalb PL1–5; zuerst lokalen Kern stabilisieren | Grafikeinbau bleibt getrennt von späterem Onlineausbau |
| Produktions- und Design-Lock V1.0, Abschnitte 2/3/9 | Mockup-Positionen verbindlich; Kamera-Kreis links unten, Angriff rechts unten; Tap-to-Sail; Effekte getrennt | Vorhandene HUD-Abweichungen werden als offene Aufgaben geführt |
| Referenzanalyse, Seiten 1 und 15 | Seafight 2013–2020 und Battle of Sea als Genrebezug, eigenes Mockup als Gesamtkomposition; freie Kartenmitte | Andere Spiele ergänzen den Vergleich, ersetzen den eigenen Visual Master nicht |

## Das erste Schiff

Asset-ID: SHIP-STARTER-001. Arbeitsname: Small Starter. Pool: starter. Erstes Produktionsziel: ein intakter Satz mit acht Fahrtrichtungen N, NE, E, SE, S, SW, W, NW, alle aus derselben schrägen Spielkamera. Erst nach Sichtprüfung und einem echten Laufzeit-Drehtest ist der Satz integriert.

Die Formsprache folgt dem kleinen klassischen Schiff der Visual Bible, Abbildung 7, obere Reihe. Die Referenz ist eine Stil- und Bauformgrundlage, kein Beweis für geometrisch perfekte Ansichten. Abbildung 8 enthält weitere frühe NPC-Kandidaten. Der Small Starter bleibt kompakt, mit einem Hauptmast, normalem Bug/Heck, Holzrumpf und neutralen Segeln. Große Fantasy-Motive bleiben für spätere Progression oder eigene Designpools reserviert.

Für die 2D-Produktion bleiben Rumpfproportionen, Mastposition, Segelgeometrie, Blickhöhe und Vergrößerung zwischen den Richtungen konstant. Rumpf, Segel und Aufbauten drehen gemeinsam; Segel dürfen nicht in jeder Richtung zur Kamera zeigen. Bug und Heck müssen klar unterscheidbar sein. Jeder Frame erhält einen Rumpf-/Wasserlinienanker. Auswahl, Trefferpunkt, Geschosse und Kielwasser richten sich daran aus.

Die in den alten GLB-Regeln geforderten vier Ansichten Front/Side/Top/Rear sind Modellierungsreferenzen aus unterschiedlichen Kamerarichtungen. Sie sind kein Ersatz für die acht 2D-Fahrtrichtungen aus einer festen Spielkamera. Der vorherige Schattenklaue-Satz ist verworfen. Die Dreimast-Fregatte unter artwork/wip/frigate-8 bleibt ein ungeprüfter Entwurf und kein Small-Starter-Kandidat.

Beschädigung und Versinken werden von intakter Darstellung getrennt. Zusätzliche beschädigte Richtungsbilder folgen nach dem stabilen intakten Satz. Rauch, Feuer und andere Effekte bleiben getrennte Ebenen; hohe HP dürfen nicht zufällig eine zerstörte Ansicht wählen.

## Abweichungen im aktuellen M3054

| Bereich | Nachgewiesener Iststand | Offene Arbeit |
| --- | --- | --- |
| Schiffsauswahl | 26 frei testbare Designs; Standardindex 22; zehn Einbild-Quellen und 16 Vier-Richtungs-Atlanten | Kanonischer Small Starter und echte Freischaltung von Medium/Large fehlen |
| Richtungsdarstellung | M3054 korrigiert Spiegelanker, Atlasreihenfolge und transparente Ränder | Kein akzeptierter neuer Acht-Richtungs-Satz; Korrekturen lösen fehlende Quellansichten nicht |
| Feueraktion | FEUER schaltet wiederholtes Schießen um | Masterkonzept Punkte 7/8 fordert manuelle Einzelsalve als Standard; Auto-Angriff separat freischaltbar |
| Kamera | Ziehen, Pinch/Zoom und Recenter vorhanden | Vorgesehener Kamera-Joystick links unten fehlt |
| Lernabschnitt | Lokaler Kampf, Hafen, Upgrades, Quests, drei Testregionen und Speicherung vorhanden | PL1–5-Ablauf, kanonische Starterprogression und Haven's Reach/Shattered Shores noch nicht vollständig umgesetzt |
| Assetherkunft | Bestehende private Testgrafiken enthalten extrahierte Referenzassets | Produktions-Lock fordert eigenständige Grafik; Referenzbestände nicht als fertige öffentliche Produktassets behandeln |
| Online | Aktiver M3054 ist lokales Gastspiel | Account, produktive Serverautorität und Crossplay sind spätere Schritte |

„Vorhanden“ bedeutet hier im aktuellen Quellstand auffindbar. Es ersetzt keinen erneuten Laufzeittest oder Gerätetest. In diesem Abgleich wurden keine neuen Gameplaytests ausgeführt.

## Versionsunterschiede offen halten

- Masterkonzept V3.8 und Produktionsliste V2 enthalten drei Starter plus 50 Hauptdesigns; frühere Passagen nennen noch 20.
- Das separate Schiffsprogressionskonzept beschreibt drei Starter, 100 reguläre Klassen und P1–P5.
- Die Begriffe Klasse und Design sind im Schiffskonzept ausdrücklich getrennt. Daher dürfen 50 Designs und 100 Klassen weder stillschweigend gleichgesetzt noch zu einer neuen gemeinsamen Liste verrechnet werden.
- Die genaue Zuordnung bleibt vor dem Ausbau der großen Flottenprogression zu konsolidieren. Sie blockiert SHIP-STARTER-001 nicht.
- Die aktuelle 2D-Entscheidung ist eine bewusste Phasenänderung gegenüber den GLB-Unterlagen; sie verwirft nicht deren Gameplay- und Produktionsziele.

## Quellenstand

Die Originaldokumente bleiben unverändert. Kontrollsummen identifizieren die geprüften Uploads:

| Datei | SHA-256 |
| --- | --- |
| ABYSSAL_DOMINION_ASSET_PRODUCTION_MASTERLIST_V2.docx | 80bd25f1d029990b834a59a1d9f86ca02c59d96ec7ef9278a83bf0ee56e08e1e |
| ABYSSAL_DOMINION_ASSET_ERSTELLUNGSREIHENFOLGE_V1.0.docx | 8605f77d7c20bcdeb66d5f5a39f1daded9f44423dfc9a552a16e0294e815e517 |
| Abyssal_Dominion_Schiffsprogression_Masterkonzept.docx | 2fafc95bbd90e51afcc5b495b11c4e19e6e8f388f8f7bec09e5f26bace7e1e80 |
| ABYSSAL_DOMINION_MASTERKONZEPT_V3.8_COMPANIONS_ARTIFACTS_AFK_REWARDS.docx | c8154307db72e7a0067efe2f27a5f1bf6e1f1918263f8fcb62b8ba3c3f3f7427 |
| ABYSSAL_DOMINION_2026_PRODUKTIONS_DESIGN_LOCK_V1.0.docx | 9df57ee4697a598b82504c894821727cc8fa68eb80748d16061b28068f24e75a |

Diese Änderung enthält den Quellenabgleich und die konkrete Produktionsvorgabe, keine neuen Sprites, Laufzeitänderungen oder APKs.
