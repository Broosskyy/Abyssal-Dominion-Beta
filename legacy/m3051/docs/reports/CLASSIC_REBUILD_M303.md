# Abyssal Dominion — Classic-Seafight-Rebuild M303
Stand: 28.10.2026
Branch: `rebuild/classic-seafight-m303`
Ausgangsbasis: letzter veröffentlichter `main`-Stand M302 (`40167d7232dc9d6fa43424f691f6ab3984c6507b`).

## Harte Produktentscheidung
Ein klassisches, seekartenbasiertes Online-Piratenspiel mit möglichst naher **Spielwirkung** an Seafight (klassische Seekarte). Ziel ist eine vergleichbare Perspektive, Schiff-zu-Wasser-Skalierung, Navigation, Zielwahl, Dauerfeuer, NPC-/Monsterkampf, Kartenwechsel, PvP und das Gefühl einer dicht besiedelten Seewelt.

**Kein Kopieren** fremder Seafight-/SeaBattles-Schiffsgrafiken, Insel-Sprites, UI-Art, Musik, Quellcode, konkreter Balanceformeln oder Marken. Eigenständige Schiffe/Designs und Lizenzprovenienz. Screenshots sind nur visuelle Referenzen.

## Repository-Strategie
- `main` = gesicherter M302-Bestand. Nicht löschen.
- `rebuild/classic-seafight-m303` = sauberer, isolierter neuer Startruntime; die alten umfangreichen M302-Systeme bleiben zunächst nur als Archiv und zum späteren gezielten Portieren vorhanden.
- `project.godot` startet im Branch die neue Scene unter `scenes/classic/classic_sea_map.tscn` (nach Boot-Commit).
- Keine Übertragung von ungetesteten M302-Contracts als angebliche Onlinefunktion.
- Kein Push nach `main` bis echte Android/Web-QA dokumentiert ist.

## Priorisierte Abnahme
1. **M303 Seekarten-Grundgefühl:** Orthografische schräge Draufsicht; Meer; Inseln; eigene und fremde Schiffe mit externer GLB; UI mit Minimap und Angriff; Click-/Tap-to-Sail; Kamera schwenken, Zoom, Recenter. Lokale Demo, **kein Online-Server**.
2. **M304 Grafik:** Eigenständige finale Schiffe, Inseln und Wasser mit Seafight-typischer Bildschirmwirkung, richtige Kontaktdichte, Schadens-VFX, UI mit gut lesbaren Touch-Zielen, Asset-Lizenzen.
3. **M305 Interaktion:** Kollisionen und Inselumfahrung, Auswahltreffer, Kanonen/Monsterharpunen, Dauerfeuer, Gegner-Lebenszyklus, Beute, Rückfahrt. Erst als lokale Tests, dann serverautoritative Integration.
4. **M306 MMO:** echte eingeloggte Spieler, autoritative Welt-/Bewegungs-/Kampfdaten, Persistenz, Kartenportal, Anti-Cheat, Chat, Gilden/PvP.
5. **M307 Content:** Schiffs-Designs/Evo, Quests, PvE-Monster, Events, Gildeninseln, Shop, Rankings.

## QA-Gates
- Jede Szene wird im Godot-Editor und dann per Desktop/Web/Android visuell getestet; keine statischen Tests als Ersatz.
- Jeder Tap muss in fahrbaren Wasser-Zielpunkt oder echte Zielauswahl münden; HUD-Taps dürfen keine Fahrziele setzen.
- Inseln dürfen niemals durchfahren oder ein Schiff dauerhaft einschließen.
- Angriffe sind unabhängig vom Fahrkurs und brauchen ein selektiertes Ziel.
- Echtgeld, Multiplayer-Zahlen, Belohnungen und Treffer niemals als „live“ bezeichnen, solange der Server nicht nachweislich angeschlossen ist.
- Bildschirm-Vergleich gegen die Referenzbilder mit Bildausschnitt, Zoom, Perspektive, Schiffsgröße, Insel-Detaillierung und HUD-Positionen.

## Asset-Herkunft / Recherche
- **Original-Seafight:** Urheber-/Produzentenreferenz Bigpoint; konkrete Blender-/Renderpipeline und Lizenzherkunft einzelner Grafiken sind nicht öffentlich nachgewiesen.
- **SeaBattles: Pirate War** von RoyaleGamesStudio: Die vom Nutzer geteilten Google-Play-Screenshots zeigen auffällig ähnliche Kartenbezeichnungen, UI-Anordnung, Schiffs-/Inseloptik. **Nicht bewiesen**, ob Originaldateien, nachgezeichnete Assets oder eigene Modelle genutzt wurden. Keine unbelegte Behauptung über Asset-Diebstahl.
- Potenzielle rechtlich sauber nutzbare Platzhalter: Kenney 2D Pirate Pack (CC0), Kenney 3D Pirate Kit (CC0) und selbst erstellte Blender-GLBs; hochwertigere Pakete nur nach Sichtung der konkreten Lizenz.
- Für den gewünschten klassisch-isometrischen Look: eigene fertige 3D-Schiffsmodelle + reproduzierbare 2.5D-Rendering-/Lighting-Pipeline oder reale GLBs in Godot mit fester obliquer Kamera; Inseln mit Biomen und gut sichtbarer Küstenlinie.
