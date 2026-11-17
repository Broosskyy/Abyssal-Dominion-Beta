# Abyssal Dominion — M386 Weltumbau / Entwurf 1

**Stand:** 17.11.2026 · **Ausgangspunkt:** M385 · **Freigabe:** Konzept und optionale UI-Vorschau, **keine Änderung der Live-Welt**

## Spielgefühl und verbindliche Grenzen

- Eigenständiges Piraten-MMO mit klassischer, sofort verständlicher Seekartensteuerung und modernem Erscheinungsbild; nicht durchgängig düster-fantastisch.
- Eine **große, charakteristische Seekarte pro Revier**, zunächst **20 Reviere**, datengetrieben erweiterbar auf **25 oder mehr**. Keine sichtbaren IDs „1/1“, „1/2“ als künftiges Hauptkonzept.
- 2D Classic (Browser und App) und 3D (App/Desktop) behalten **dieselben autoritativen Positionen, Geschwindigkeiten, Kollisionskörper, Wegpunkte und Serverbewegungen**. M376 nicht verändern.
- Keine 20 leeren Wasserflächen. Jedes Revier braucht erkennbare geografische Silhouette, eigene Tätigkeiten, Häfen/Ankerplätze, NPC-Rollen, Monster und wiederkehrende Ereignisse.
- Eigene Modelle, eigene Inselillustrationen, eigene Geschoss-/Trefferanimationen. Vorhandene 3D-/2D-Assets nicht automatisiert ersetzen, solange die laufende Gestaltung noch verfeinert wird.

## Vorgeschlagene Weltordnung

Die 20 Einträge samt individueller Kurzbeschreibung liegen maschinenlesbar in `rebuild/m3052/realm_catalog.gd`.

| Region | Reviere | Stil | Schwerpunkt |
|---|---|---|---|
| Küstengewässer | 01–04 | tropisch, helle Buchten, Riffe | Einstieg, Handel, Konvois, Bergung |
| Handelsrouten | 05–08 | Häfen, Inselketten, Nebel, Klippen | Schiffe, Eskorten, Piraten, Schatzsuche |
| Nördliche Gewässer | 09–12 | Eis, Fjorde, offenes kaltes Meer | seltene Fracht, Monsterjagd, Erkundung |
| Umkämpfte See | 13–16 | Forts, Wracks, Sturmfronten | PvP, Gilden, Flotten- und Welt-Events |
| Tiefe Gewässer | 17–20 | Ruinen, Strömungen, seltene Inseln | Gruppenbosse, Relikte, Endgame |

Jede Karte bekommt mindestens: **3 Landschaftstypen**, **1 Hafen/Ankerplatz**, **2 sichtbare Wahrzeichen**, **3–5 NPC-Rollen**, **1–3 Monsterarten**, **1 Sammel- oder Bergungssystem**, **2–4 regionale Aufträge** und mindestens **1 optionale Ereignisvariation**. Diese Zahlen sind Entwurfsziele, noch keine vorhandenen Features.

## Reisen – Hybrid statt ausschließlich Kartenränder

Vorgesehen sind drei unterscheidbare Verbindungen:

1. **Seewege / Engstellen**: bewusst erkennbare Durchfahrten auf der Seekarte, die man wirklich anfährt; kein automatischer Übergang über jede offene Kartenkante.
2. **Hafenüberfahrten**: eine ausdrücklich bestätigte Route zwischen passenden Häfen/Regionen; Kosten, Cooldown und Freischaltungen bleiben zunächst offen.
3. **Besondere Portale / Strömungen**: optionale Abkürzungen zu Events, versteckten Seegebieten oder gefährlichen Revieren; nicht jeder Knoten ist überallhin verbunden.

Die `neighbors()`- und `passage_type()`-Funktionen beschreiben **nur einen konzeptionellen Graphen**. **Sie führen keine Reisen aus.** In der Live-Version gelten weiterhin die bisherigen 40 Karten und die originalen Randüberfahrten.

### Reise-UX später

In Weltkarte Karte wählen → **Details** (Level, Gefahren, Aktivitäten, mögliche Wege) → **Route anzeigen** → zur tatsächlich erreichbaren Passage/Hafenanlage navigieren → Wechsel nach Zugangsprüfung. Kein Teleport von jedem beliebigen Kartenpunkt. Keine Überfahrt unter Treffer-Cooldown, keine Umgehung durch UI.

## Technische Migration, erst nach gesonderten Tests

Derzeit: 40 persistente Seekarten-IDs, originale Bonuskarten **3–5**, pro Seekarte `8800×6400` Weltpixel, alte Kartengrenzen, Gildeninsel-Besitzstände, Level-Gates und bestehende Server-Protokolle.

**Phase A – M386 (dieser Branch):** nur neues Revierverzeichnis, testbarer Verbindungsgraph, anklickbare Weltkarten-Vorschau unter Seekarten → WELTKARTE. Fallback auf bisherige Welt. Keine Änderung an `content.gd`, `simulation.gd`, `world_server.py`, Save-Schema, `near_portal()` oder M376-Physik.

**Phase B – technische Weltmigration:** neues persistentes Revier-Kennzeichen und `world_schema`. Alte 2 Seekarten eines Tiers werden einem Revier zugeordnet; Positionskonvertierung und Gildenbesitz ausdrücklich und reversibel. Physische Karten könnten z. B. gestreamte **2×8800×6400**-Abschnitte verbinden; zunächst Leistung auf Mobilgeräten messen, bevor endgültige Größe festgelegt wird. Server/Browser/Android in einem konsistenten Protokollwechsel, nicht unabhängige Halb-Migrationen. Bonusinstanzen und Event-Belohnungen getrennt halten. Map-Inhalte nur nach serverseitig validierter Reiseprüfung wechseln. Bestehende aktive Fahrwege beim Wechsel korrekt beenden, nicht beim Grafikmoduswechsel.

**Phase C – richtige Reisen:** Portal-/Hafenorte als eigene sichtbare Objekte mit kollisionsgeprüftem Wasserzugang, Ankunftspunkten, Level-Gates, Kampf-Cooldown und klarer Benutzerführung. Neue Überfahrts- und Crossplay-Tests, keine Auto-Reise über die gesamte Kante.

**Phase D – Inhaltsintegration:** Datensatz je Revier für Hintergrund, Inselanordnung, Spawn-Rollen, Quests, Events, handelbare Gegenstände, Jagdgebiete, Gildeninseln und Portale. Nicht bloß HUD-Text austauschen: Spawnmanager, Questfortschritt und Belohnungsledger müssen dieselben IDs verwenden.

## Assets und Animationen als austauschbare Schichten

- **Schiffe**: einzelnes Original-GLB/Texture-Set, Classic-2D aus 8 Richtungen, gleiche Kollisions-/Wasseranker in beiden Modi, Elite-Stufen unterscheiden sich wirklich in ihrer Anmutung.
- **Inseln**: Originalgrafik pro Biome oder Wahrzeichen; eigene Kollisionsmaske mit unveränderlichem Navigationsanker; Küsten-/Brandungseffekt separat, Eingänge zum Hafen frei.
- **Monster**: eindeutige Silhouetten für z. B. Riffkrabbe, Seeschlange, Wal-/Eisbestie, Tiefenwächter; Idle, Treffer, Angriff, Tod als unabhängig skalierbare VFX; echte Spawn-/Harpunenregeln aus der Simulation.
- **Munition**: Daten pro Typ (Schaden, Reichweite, Zielarten, Cooldown) getrennt von Visuals (Mündung, Flug, Treffer, Zahlen, Zerstörung); selbst erstellte Animationen in austauschbaren Atlanten. Keine Stats an Animationen koppeln.
- **VFX**: Treffer-/Schadenszahlen, Rauch, sinkender Rumpf, Schildabsorption, Spezialitem-Feedback. Partikelbudget browserfreundlich, Animation pro Spieleroption reduzierbar.
- **Editor später**: Revier-Templates, Seed-Zufallsgenerator, Insel-/Objektplatzierung, Wassertiefen-Layer, NPC-Spawns, Loot-/Quest-Trigger und eine 2D/3D-Vorschau; Daten als Dateien exportierbar statt im Code versteckt.

## Bedienbarkeit

Die Weltkarte soll nicht nur nummerierte Punkte darstellen: Zonenfilter, geografische Symbole, Anzeigen für „hier“, „gesperrt“, „entdeckt“, „Gildenbesitz“ und auf Wunsch eine markierte Überfahrtsroute. Mobil nur zwei Spalten, große Touchflächen, klare Zurück-Navigation. Gameplay-Panels aufräumen; neue Features lieber in eigene Tabs integrieren als die Kampfleiste überladen.

## Qualitätskriterien vor produktiver Aktivierung

- 20 eindeutige Reviere, fünf Zonen, alle Graphknoten erreichbar, keine ungültigen Verbindungen.
- Jeder der 40 alten Seekarten-IDs hat genau **eine** beabsichtigte Nachfolgerzuordnung; Bonuskarten werden **nicht** in normale Reviere verschoben.
- Alte M385-Spielstände, Gildenbesitz, Decks, PvP-Rang und Währungen bleiben erhalten.
- Browser (2D) und App (2D/3D) haben nach Reisen dieselbe Position und nutzen identische serverseitige Wege; Retap während der Fahrt und Hindernisse bleiben korrekt.
- Hafen/Seeweg/Portal nicht im Kampf ausnutzbar; Ankunft nie auf Land und ohne unbeabsichtigte sofortige Rückreise.
- Keine Renderregressionen auf mobilen 852×393- und 720×405-Ansichten; Assets über kleine Streamingpakete nachladen.
- Das Konzept gilt erst als umgesetzt, wenn Godot-Tests, echte Browser-/Android-Prüfungen und Gameplay-Abnahme bestanden sind.

**Status M386:** Entwurf und Vorschau im separaten Branch. Keine Veröffentlichung oder Live-Umstellung.
