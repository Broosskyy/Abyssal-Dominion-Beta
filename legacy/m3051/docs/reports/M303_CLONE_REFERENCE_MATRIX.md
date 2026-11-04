# M303 — Seafight-Nachfolger: Vergleich und definitive Referenzaufteilung
Datum: 2026-10-28

## Ergebnis
**SeaBattles 1.24.0 bleibt unsere Hauptreferenz für das visuelle Spielgefühl, nicht als fremder kopierter Code- oder Asset-Kern.** Der eigenständige Abyssal-Dominion-Rebuild bleibt im Branch `rebuild/classic-seafight-m303`.

### 1) SeaBattles: Pirate War — vom Nutzer bereitgestellte Android-.apks (statische Analyse)
- Unity-Client, IL2CPP; Schiffsgrafik-Texturen und Benennungen wie Elite-Schiffe, FlyingDutchman etc. wurden bereits in der früheren Asset-Sichtung festgestellt.
- Die in diesem Chat mit eigener statischer Auswertung der Datei `assets/bin/Data/Managed/Metadata/global-metadata.dat` bzw. `global-metadata.dat` gefundenen Strings umfassen:
  - `Skills`, `expertSkillMenu` → Indiz für ein Skills-Menü, keine verifizierte vollständige Talentbaum-Spielmechanik.
  - `Bastion`, `ClanBastions`, `GuildTowerList`, `GuildTowerSlotView`, `towerHealthFill`, `upgradeTowerIcon` → starke Indizien für Gildenfestungen / Türme; nicht mit individuellen Seafight-Schiffskastellen gleichsetzen.
  - `EliteClassesWindow`, `ShipUpgradeWindow`, `CannonCapacity`, `ShipEquipmentWindow`, `crewSummary`, `GuildIslandTab` → zusätzliche Clientoberflächen.
  - Die wörtlichen Bezeichnungen `Talent` bzw. `Castle` wurden bei den statisch lesbaren ASCII-Metadaten nicht gefunden, was deren Fehlen **nicht beweist**.
- Metadaten zeigen nur, dass Strings/Klassen existieren; Online-Verfügbarkeit, Serverfähigkeit und tatsächlich spielbare Menüs müssen im Spiel getestet werden.
- Fremde APK/Assets werden **nicht** nach GitHub committed oder für einen kommerziellen Build kopiert. Der Nutzer kann uns echte Spiel-Screenshots und Clips als Analyse-Referenzen liefern.

### 2) Legend Pirates (Corner Games) — Referenz: individuelle Kastelle/Presets/Langzeitprogression
- Die offiziellen App-Store-Versionshinweise dokumentieren **castle & preset system** (2.0.1, Mai 2026), **castle mobile fix** (2.0.2) und **Daily Castle Tax fixes** (2.0.3). https://apps.apple.com/gb/app/legend-pirates/id6736532244
- Offizielle Entwickler-Seite dokumentiert isometrisches PvP/PvE, Kanonen, Ausrüstung, Fähigkeiten, Schiffsausbau, Quests, Events, Gilden: https://www.cornergames.com/games/legend-pirates
- Bonuskarten und Elitelevel sind aus Community-Rezensionen bekannt, vor Implementierung Screenshots oder offizielle Feature-Angaben gegenprüfen.

### 3) Battle of Sea (Gamepatron) — Referenz: Gildeninseln, Allianzen, Kanonen, Decks, Content
- Offizielle Forum-Anleitung: Gildeninseln ab Kartenlevel 5, 12 zerstörbare Türme, Tower-Upgrades, Eigentümerbonus. Die dokumentierten Zahlen gehören **nicht** in unseren Balance-Code. https://forum.battleofsea.com/en/thread-13
- Offizielle Patchnotes (laufend): Gildeninsel-Tab, weitere Schiffsklassen, 25kg-Kanonen, Decksystem, mobile 2D-Meer-Option und PvP-/Event-Anpassungen: https://forum.battleofsea.com/en/thread-3
- Offizielle Android-App: https://play.google.com/store/apps/details?id=com.gamepatron.battleofsea

### 4) Son Korsan (Consala Games) — Referenz: PvP/Arena/Missionen/strategische Gilden-Angriffe
- Offizielle Steam-Beschreibung listet Tablet/Mobil, Schiffaufbau, Gilden-Inselangriffe, Quests, Schatzkarten, PvP/5v5 und Capture-the-Flag:
  https://store.steampowered.com/app/645830/Son_Korsan/

### 5) Original Seafight (Bigpoint) — Referenz: Talente/Kastelle-Konzept
- Offizielle Forum-Diskussion dokumentiert getrennte Skills und Kastelle; der Unterschied ist entscheidend:
  https://board-en.seafight.com/threads/new-player-cannons-talents-castle.182824/
- Eigene Progression und Formeln entwickeln statt konkrete Bigpoint-Werte/Art zu kopieren.

## Verbindliche M303-M307-Baufolge
1. **M303 Seekarte/Schiffe/Bewegung**: Seafight-/SeaBattles-ähnliche Perspektive und Zoom, richtungsabhängige Schiffsanimation (2D Atlas oder 3D), Kurssetzung, Segelbewegung, Zielauswahl, Kartenwechsel, Inselkollision. Visuelle Abnahme auf Android-Landscape anhand der vom Nutzer gelieferten Screenshots.
2. **M304 Grundkampf**: Kanonen, Distanz, unterschiedliche Munition, Harpunen gegen Monster, Dauerfeuer, Schäden, Hüllen- und Reparaturlogik, Loot/NPC-Spawns. Erst lokal getestet, danach Serveranbindung.
3. **M305 Langzeitaufbau**: **individuelle Schiffskastelle / ausrüstbare Module / mehrere Presets** und **separater Talentbaum** mit eigenen Werten, Kosten und Progression; Kanonenplätze, Decks, Crew, Schiffsdesigns, Eliteklassen.
4. **M306 Echte Onlinewelt**: serverautoritative Bewegung/Kampf/Inventar/Ökonomie, Karten und Portale, Chat und Accounts, Quest-/Event-Spawn, Schutz/Gilden-PvP.
5. **M307 Gildeninseln/Großcontent**: Eroberung, Türme, Reparatur, Allianzen, Gildenbuffs, Boss- und Bonuskarten, Loot/Events/LiveOps.

## Fachliche Implementierungsgrenzen
- **Kastelle**: individueller Account-/Schiffsbau-Featurebaum, gesonderte Presets, passive Boni.
- **Talente**: eigene Pfade (z. B. Angriff, Seefahrt, Verteidigung), Punktevergabe und Respec, persistiert auf Server.
- **Gildenfestungen**: Weltgebäude mit Eigentum, Türmen und belagerungsartigen Interaktionen; dies ersetzt keine Kastelle.
- **Schiffsgrafik**: 16-/32-Richtungs-Atlanten nur als austauschbare Technik; APK beweist bislang nicht die exakte Richtungsanzahl jedes Schiffs.
- Während neuer Kern entwickelt wird, M302-Altcode auf main sichern; keine fake-online Screenshots, kein Release ohne native QA.
