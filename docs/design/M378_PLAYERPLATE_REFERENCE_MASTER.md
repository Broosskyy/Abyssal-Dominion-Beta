# Abyssal Dominion · M378 Playerplate / Deck / Schiffsansicht – Masterregel

Status: **verbindliche Gestaltungsvorgabe**, basierend auf den vom Projektinhaber bereitgestellten Bildern `208798.gif`, `208799.gif`, `208801.jpg`, `208802.jpg`, `208803.jpg` (16.11.2026). Keine Übernahme von Fremdgrafiken. Alle Ornamente sind eigenständig gezeichnete, kleine Vektorelemente.

## Bildreferenzen richtig interpretiert

- **Bild 3 / 208801.jpg**: Grundform des Deckabzeichens – kompakter, fast symmetrischer goldfarbener Kranz; 2 obere Schädel, seitliche Kronen/Zierarme, mittige weiße Zahl und kleiner unterer Totenkopf. Dünne blaue/helle Stufenmarkierungen als Statuszeile.
- **208798.gif**: Dunkles 3/4-Schiff, grüner gepunkteter Ring, unter dem Rumpf `[TAG] Spielername`, optionale rote Admin-Rolle, zwei schmale Statusleisten, dichtes Deckabzeichen. Die dunkle Renderqualität ist ein Stilhinweis, *kein* neues Master-Rumpfmodell.
- **208799.gif**: Goldschiff in derselben schrägen Draufsicht; Ring bleibt grün, leicht funkelnde Schiffseffekte sind separat zur Ringfarbe. Die Statuszeilen und das Deckabzeichen behalten dieselbe feste Position.
- **208802.jpg**: HUD-/Wasseransicht und vier Statusleisten des größeren Bildausschnitts; **nicht** die Komposition des Abzeichens ersetzen.
- **208803.jpg**: zusätzliche Detailreferenz für seitliche Rang-/PvP-Symbole, Blatt-/Kronenzierwerk und das zentrierte Abzeichen.

## Verbindlicher Aufbau des Spielerschiffs

1. **Schiff selbst:** Original-GLB im nativen 3D-Modus; Browser/Classic rendert die aus genau diesen GLBs erzeugten 8 Blickwinkel. Schräg von oben (3/4-Draufsicht), bugwärts korrekt, Masten/Segel nicht spiegeln. Keine Zweitmodelle, keine andere physische Flugbahn. Bestehende Kameraorientierung beibehalten, bis direkte ingame Vergleichsaufnahmen eine sichere Anpassung erlauben.
2. **Grüner Ring:** Eine einzige, im Wasser liegende **punktierte Ellipse** um das eigene Schiff mit **44 gleichmäßig verteilten Punkten**; Farbe `#31E65D`, unabhängig von Schiffsdesign, Rang oder temporären Buffs. Ellipsenradien für das eigene Schiff aus Modell-Länge `max(36, length×0.44)` und `max(16, length×0.185)`. Die Kreislinie bleibt sehr schwach. Keine Leuchtplatte oder 3D-Hovering-Platform, keine Änderung der Hitbox/Klickkoordinaten. Ein Zielgegner behält seine eigene, andersfarbige Zielmarkierung.
3. **Name:** direkt unter dem Rumpf, horizontal mittig. `(Piratenrang-Icon) [Gildenkürzel] Spielername (BP/PvP-Rang-Icon)`. Gildenkürzel goldgelb, übriger Name gut lesbar. Nur Admin-/Teamrollen bei Berechtigung ergänzen.
4. **Darunter:** Spieler-ID dezent; schmale **grüne HP-Leiste** sowie **blaue Schildleiste**. Die Referenz zeigt verschiedene HP/VP-Farbvarianten; Abyssal behält sein funktionierendes HP-Grün/Schild-Blau für konsistentes Gameplay. **Keine HP-Zahlen am Schiff**; die Zahlen sind im oberen HUD.
5. **Deckabzeichen:** unmittelbar unter den Leisten, **kein schwebendes Kartensystem** und keine leeren großen Quadrate. Zwei Schädel über einer mittigen Zahl, Kronen links/rechts, feine metallische Zierarme, unterer kleiner Schädel. Unten **zehn winzige echte Statusmarkierungen** in zwei Reihen zu fünf. Farbe entspricht dem realen Standarddeck-Material (Gold/Perlen/Kristall); leer = dunkel.
6. **Drei Sonderdecks:** links `Gezeiten` (türkis), rechts `Runen/Sturm` (blau), unten `Korsaren/Bergung` (warmgold). Die Ornamente existieren auch deaktiviert als altes Metall; nur ein **tatsächlich laufender Buff** beleuchtet seinen Platz. Sonderdecks ersetzen keine der 10 normalen Deckpositionen. Kristallsegen bleibt eine eigene Buff-Anzeige.
7. **Zahl im Deckabzeichen:** zeigt derzeit die **echte Kanonenplatz-Kapazität** aus `sim.cannon_slots()`. Eine Referenzzahl `411/656` wird **nicht** als erfundene Deckstärke ins Spiel kopiert. Ein separates Deck-Ranking ist erst einzuführen, wenn es eine eigene definierte Spielmechanik gibt.

## Größen & mobile Abstände

- Name und zugehörige Icons: vorhandene, scharfe native Schrift in der separaten `ShipPlateScreenSpace`-Ebene; keine Größenänderung beim Schwenken des 3D-Modells.
- Grüner Ring: Skala mit tatsächlicher Schifflänge **im Spielraum**; Bead-Dicke in Bildschirmpixeln stabil bei Zoom.
- Deckabzeichen: lokale Referenzskalierung `r=6×_plate_pixels()`. Symmetrische Kronen etwa `±7.25r`; zwei Schädel `±1.36r`. Mittelzahl `y=2.05r`, Untericon `y=4.05r`, zehn Statusmarkierungen `y=5.45r`.
- Überlagerungen vermeiden: Deckabzeichen nur unter den HP/Schildstreifen, niemals in das eigene Segel oder benachbarte Menü-Buttons schieben. NPC-Abzeichen nicht anzeigen.
- Unabhängige Kamerapositionen für 2D und 3D zulässig, **aber exakt ein gemeinsamer physischer Fahrtweg** und dieselben Weltkoordinaten.

## Technische Integration (M378)

- `sea_map.gd`: feste Spieler-Ringfarbe und reine 2D-Wasserlinienzeichnung der 44 grünen Beads; ansonsten Zielringe unverändert.
- `sea_marks.gd`: `reference_deck_geometry` und aktualisiertes `deck_badge` mit echten Deck-/Buffdaten.
- `ship_plate_overlay.gd`: bestehende pixelgenaue Playerplate bleibt Träger; durch den bestehenden `deck_badge`-Aufruf wird die neue Gestaltung im Browser-2D **und** nativen 3D automatisch verwendet.
- `tests/m378_reference_playerplate_test.gd`: Symmetrie, Größen und tatsächliche Spielwerte, Ringfarbe/Geometrie, unveränderte Spielmechanik.

## Abgrenzung

Diese Masterregel übernimmt **Layout, Rangordnung, Blickwinkel und Abstände** aus der Inspiration – nicht fremde Wappen, Grafiken, Schiffsmodelle oder Texturen. Die genaue ästhetische Feinabstimmung des 3D-Winkels und der Ornamentdetails erfolgt anhand echter Browser-/Android-Aufnahmen; M376-Multiplayer/Steuerung hat Vorrang vor kosmetischen Wünschen.
