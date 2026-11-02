# M303 — Referenzvergleich und Content-Strategie (28.10.2026)

## Entscheidung
**Nicht** den geschützten SeaBattles-Client als Quellcode-Basis kopieren. Der bestehende Godot-Rebuild auf `rebuild/classic-seafight-m303` bleibt unser eigenes Spiel. SeaBattles dient primär als **Bildschirm-/Bewegungs-/HUD-Referenz**, Legend Pirates und Battle of Sea als **Feature-/Fortschrittsreferenzen**, Original-Seafight als langfristige **Content-Checkliste**. Vorbildmechaniken unabhängig implementieren, Texturen, UI, Namen und geschützte Originalressourcen nicht in unseren distributierbaren Build übernehmen.

## Nachgewiesene Features und Quellen
| Vorbild | Verifizierbare Systeme | Quelle | Grenze |
| --- | --- | --- | --- |
| SeaBattles: Pirate War (1.24.0) | APK ist Unity / IL2CPP und enthält Texturen für Schiffsnamen. Visuell klassischer Seafight-Look auf Nutzerscreenshots. | Nutzerupload `SeaBattles (1.24.0).apks`; Screenshot | Nicht aus der Texturdateiliste schließen, dass keine Talente/Kastelle implementiert sind. Engine/Clientdaten allein belegen nicht serverseitige Inhalte. |
| Legend Pirates (Corner Games) | Explizite Update-Notizen zu **castle**, Presets, Calypso-Event, täglichen Kastellsteuern, Bonuskarten im Captain-System, Saison-Events. Android/iOS/Windows/macOS. | https://apps.apple.com/de/app/legend-pirates/id6736532244 ; https://www.legendpirates.com/ | Exakte Mechanik/Qualität und aktueller Android-Stand bedürfen eines Spieltests. |
| Battle of Sea | Offizieller Guide listet Skill Levels, Ship Points, Deck System, Guild Islands, Guild Chest Event, Event Maps und Bonusmaps, Boss-NPCs und Gruppen-System. | https://www.battleofsea.com/en/blog ; https://forum.battleofsea.com/en/thread-161 ; https://www.battleofsea.com/ | Ein Decksystem ist nicht automatisch das originale Seafight-Kastellsystem; originale Skillpfade und Balance nicht übernommen. |
| SonKorsan | Mobile maritime MMO-Alternative mit Seafight-artigem Kampfsystem. | https://apps.apple.com/de/app/sonkorsan-pirate-game/id583643255 | Funktionsumfang und Kastelle/Talente nicht belastbar bestätigt; Nutzerbewertungen stark gemischt. |
| Sea Bandits (Retro Seafight) | Entwickler beschreibt eigene C++-Engine; Konzept enthält isometrische Karten/A*-Routing, Client/Server, NPC, Gildeninseln, Events/Quests/Mapwechsel; öffentliche Server-/Client-Dateien waren eine Ankündigung. | https://www.elitepvpers.com/forum/seafight/4799648-sea-bandits-retro-seafight.html ; https://www.patreon.com/seabandits | Keine belegte aktuelle Open-Source-Lizenz/öffentlich nutzbarer Code; keine Übernahme ohne Lizenzprüfung. |
| Original Seafight | Welt, Ausrüstung, Kastelle, Talente, Kapitänssystem, PvP, Gilden, Bonuskarten | https://www.bigpoint.net/seafight ; https://www.seafight.com/devBlog/lang/en | Keine Original-Assets und keine Originalformeln kopieren. |

## Nächste Releases nach der spielbaren M303-Karte
- M304: Sprite-Provenienz, eigene Richtungs-Spritesheets, Rotation/Bewegung (UI und Reaktionszeit auf **Referenzwirkung** ausgerichtet), Inselkollision, Fahrpfade, Meer und Schiffs-/Inselmaßstab.
- M305: Eigene Spielsysteme: Zielwahl, Kanonen, Harpunen, Auto-Fire, Treffer-Feedback, Loot, Reparatur, NPC-KI mit Tests. Lokale Simulation klar von Onlinezustand trennen.
- M306: **Kastell-ähnliche Upgrades** und **Talentbäume** nach eigener Item-/Skill-/Balance-Spezifikation. Schiffslevel/Elite, Kanonen, Crew/Kapitäne, Deck-Slots.
- M307: PvE-/PvP-Kartenübergänge, Bonuskarten, Gruppen, Gildeninseln, Events, Quests, Ranglisten.
- M308+: Autoritativer Online-Server, Accounts, Persistenz, Match-/Weltserver, Economy, Anti-Cheat. Kein behaupteter Multiplayer vor echter End-to-End-QA.

## Priorität der drei Referenzen
1. SEA BATTLES: Wie fühlt sich das **Sekunde für Sekunde** beim Fahren und Schießen an?
2. LEGEND PIRATES: Welche **Fortschrittsmenüs, Kastelle, Presets, Kapitäne** braucht ein langfristiges MMO?
3. BATTLE OF SEA: Welche **Deck-/Skill-Ökonomie, Gildeninseln, Bonuskarten und PvE-Events** machen die Welt vielfältig?

## Offener Nachweis
Eine APK-Analyse kann lokale Assets/Client-Codestrukturen zeigen, aber nicht alle Account-/Server-Funktionen belegen. Die Behauptung „SeaBattles hat keine Kastelle/Talente“ ist ohne Gameplay-Test nicht bewiesen. Kein zusätzlicher Nutzerdownload nötig, bevor dieser Referenzplan verwendet wird.
