# Abyssal Dominion · M378 Playerplate / Deck / Schiffsansicht – Masterregel

Status: **verbindliche Gestaltungsvorgabe nach M379-Screenshotkorrektur**, basierend auf den vom Projektinhaber bereitgestellten Bildern `208798.gif`, `208799.gif`, `208801.jpg`, `208802.jpg`, `208803.jpg` (16.11.2026). Keine Übernahme von Fremdgrafiken. Alle Ornamente sind eigenständig gezeichnete, kleine Vektorelemente.

## Bildreferenzen richtig interpretiert

- **Bild 3 / 208801.jpg**: Grundform des Deckabzeichens – kompakter, fast symmetrischer goldfarbener Kranz; 2 obere Schädel, seitliche Kronen/Zierarme, mittige weiße Zahl und kleiner unterer Totenkopf. Dünne blaue/helle Stufenmarkierungen als Statuszeile.
- **208798.gif**: Dunkles 3/4-Schiff, grüner gepunkteter Ring, unter dem Rumpf `[TAG] Spielername`, optionale rote Admin-Rolle, zwei schmale Statusleisten, dichtes Deckabzeichen. Die dunkle Renderqualität ist ein Stilhinweis, *kein* neues Master-Rumpfmodell.
- **208799.gif**: Goldschiff in derselben schrägen Draufsicht; Ring bleibt grün, leicht funkelnde Schiffseffekte sind separat zur Ringfarbe. Die Statuszeilen und das Deckabzeichen behalten dieselbe feste Position.
- **208802.jpg**: HUD-/Wasseransicht und vier Statusleisten des größeren Bildausschnitts; **nicht** die Komposition des Abzeichens ersetzen.
- **208803.jpg**: zusätzliche Detailreferenz für seitliche Rang-/PvP-Symbole, Blatt-/Kronenzierwerk und das zentrierte Abzeichen.

## Verbindlicher Aufbau des Spielerschiffs

1. **Schiff selbst:** Original-GLB im nativen 3D-Modus; Browser/Classic rendert die aus genau diesen GLBs erzeugten 8 Blickwinkel. Schräg von oben (3/4-Draufsicht), bugwärts korrekt, Masten/Segel nicht spiegeln. Keine Zweitmodelle, keine andere physische Flugbahn. Bestehende Kameraorientierung beibehalten, bis direkte ingame Vergleichsaufnahmen eine sichere Anpassung erlauben.
2. **Grüner Ring:** Eine einzige, im Wasser liegende **punktierte Ellipse** um das eigene Schiff mit **44 gleichmäßig verteilten Punkten**; Farbe `#31E65D`, unabhängig von Schiffsdesign, Rang oder temporären Buffs. Ellipsenradien für das eigene Schiff aus Modell-Länge `max(36, length×0.38)` und `max(16, length×0.145)`; der Mittelpunkt liegt um `length×0.065` tiefer an der Wasserlinie. Die Kreislinie bleibt sehr schwach. Keine Leuchtplatte oder 3D-Hovering-Platform, keine Änderung der Hitbox/Klickkoordinaten. Ein Zielgegner behält seine eigene, andersfarbige Zielmarkierung.
3. **Name:** direkt unter dem Rumpf, horizontal mittig. `(Piratenrang-Icon) [Gildenkürzel] Spielername (BP/PvP-Rang-Icon)`. Gildenkürzel goldgelb, übriger Name gut lesbar. Nur Admin-/Teamrollen bei Berechtigung ergänzen.
4. **Darunter:** Spieler-ID dezent; schmale **grüne HP-Leiste** sowie **blaue Schildleiste**. Die Referenz zeigt verschiedene HP/VP-Farbvarianten; Abyssal behält sein funktionierendes HP-Grün/Schild-Blau für konsistentes Gameplay. **Keine HP-Zahlen am Schiff**; die Zahlen sind im oberen HUD.
5. **Deckabzeichen:** unmittelbar unter den Leisten, **kein schwebendes Kartensystem** und keine leeren großen Quadrate. Zwei Schädel über einer mittigen Zahl, Kronen links/rechts, feine metallische Zierarme, unterer kleiner Schädel. Unten **zehn winzige echte Statusmarkierungen** in zwei Reihen zu fünf. Farbe entspricht dem realen Standarddeck-Material (Gold/Perlen/Kristall); leer = dunkel.
6. **Drei Sonderdecks:** links `Gezeiten` (türkis), rechts `Runen/Sturm` (blau), unten `Korsaren/Bergung` (warmgold). Die Ornamente existieren auch deaktiviert als altes Metall; nur ein **tatsächlich laufender Buff** beleuchtet seinen Platz. Sonderdecks ersetzen keine der 10 normalen Deckpositionen. Kristallsegen bleibt eine eigene Buff-Anzeige.
7. **Zahl im Deckabzeichen:** zeigt derzeit die **echte Kanonenplatz-Kapazität** aus `sim.cannon_slots()`. Eine Referenzzahl `411/656` wird **nicht** als erfundene Deckstärke ins Spiel kopiert. Ein separates Deck-Ranking ist erst einzuführen, wenn es eine eigene definierte Spielmechanik gibt.

## Größen & mobile Abstände

- Name und zugehörige Icons: vorhandene, scharfe native Schrift in der separaten `ShipPlateScreenSpace`-Ebene; keine Größenänderung beim Schwenken des 3D-Modells.
- Grüner Ring: Skala mit tatsächlicher Schifflänge **im Spielraum**; Bead-Dicke in Bildschirmpixeln stabil bei Zoom.
- Deckabzeichen: lokale Referenzskalierung `r=5.5×_plate_pixels()`. Symmetrische Kronen etwa `±6.5r`; zwei Schädel `±1.20r`. Mittelzahl `y=1.9r`, Untericon `y=3.95r`, zehn Statusmarkierungen `y=5.5r`.
- Überlagerungen vermeiden: Deckabzeichen nur unter den HP/Schildstreifen, niemals in das eigene Segel oder benachbarte Menü-Buttons schieben. NPC-Abzeichen nicht anzeigen.
- Unabhängige Kamerapositionen für 2D und 3D zulässig, **aber exakt ein gemeinsamer physischer Fahrtweg** und dieselben Weltkoordinaten.

## Technische Integration (M378)

- `sea_map.gd`: feste Spieler-Ringfarbe und reine 2D-Wasserlinienzeichnung der 44 grünen Beads; ansonsten Zielringe unverändert.
- `sea_marks.gd`: `reference_deck_geometry` und aktualisiertes `deck_badge` mit echten Deck-/Buffdaten.
- `ship_plate_overlay.gd`: bestehende pixelgenaue Playerplate bleibt Träger; durch den bestehenden `deck_badge`-Aufruf wird die neue Gestaltung im Browser-2D **und** nativen 3D automatisch verwendet.
- `tests/m378_reference_playerplate_test.gd`: Symmetrie, Größen und tatsächliche Spielwerte, Ringfarbe/Geometrie, unveränderte Spielmechanik.

## Abgrenzung

Diese Masterregel übernimmt **Layout, Rangordnung, Blickwinkel und Abstände** aus der Inspiration – nicht fremde Wappen, Grafiken, Schiffsmodelle oder Texturen. Die genaue ästhetische Feinabstimmung des 3D-Winkels und der Ornamentdetails erfolgt anhand echter Browser-/Android-Aufnahmen; M376-Multiplayer/Steuerung hat Vorrang vor kosmetischen Wünschen.

## M379 – Screenshotkorrektur

Die erste Ingame-Version von M378 zeigte übergroße breite Stahlflügel, ein auseinandergezogenes HUD, einen Ring im oberen Segelbereich und eine zu senkrechte Schiffsperspektive. Das entspricht **nicht** der akzeptierten Referenzform.

- Leichte, symmetrische goldene Filigrane ersetzen die breiten Metallarme; Sonderdeck-Effekte markieren die Endpunkte nur bei realem Buff.
- Namen höchstens 14-pt Basisgröße; Rangzeichen näher an den Namen, dezente 7-pt-ID; HP auf y=19, Schild auf y=28 und Deckzentrum auf y=47, jeweils mit nativer Pixelanpassung.
- Der Spieler-Ring bleibt grün, mit 44 feineren Punkten und kleinerem Radius; sein Mittelpunkt wird auf den unteren Wasserkontakt versetzt. Keine Änderung an Hitbox, Fahrtweg oder Zielkoordinaten.
- 2D-Classic-Sprites werden aus originalen GLB-Modellen unter **48° 3/4-Neigung** gebacken, exakt wie die native 3D-Kamera. Acht echte Richtungsansichten bleiben verfügbar; keine künstliche Drehung oder 2.5D-Simulation.
- Künftige Änderungen müssen mit **frischen Browser-Captures** überprüft werden und nicht nur syntaktisch getestete Draw-Funktionen.

## M380 – visuelle Korrektur nach Referenzvergleich vom 16. November 2026

Die vorliegenden originalen Spielbilder zeigen **eine deutlich sichtbare, kompakte, hochwertige Deckkomposition** unter dem Namen; weder miniaturhafte Dekoration noch eine riesige Befestigungsleiste. Nach den tatsächlichen M379-Screenshots sind verbindlich:

- **Schiff:** Spieler (auch Remote-Spieler) erhalten einen Rendermaßstab von **0,85** des bisherigen Rumpfs; die physische Position, Trefferzone, Geschwindigkeit, Kursberechnung und Weltmodelle bleiben gleich. NPC-/Monstergrößen bleiben unverändert. Sowohl echte GLB-Darstellung als auch die 8 aus denselben GLBs gebackenen Browseransichten benutzen diese gemeinsame Darstellungslänge.
- **Blickwinkel:** Native 3D-Kamera und der Classic-2D-Spritebäcker verwenden dieselbe **56° Neigung ab der vertikalen Kamerarichtung**, sodass Rumpf/Seiten stärker zur Geltung kommen. Weltbewegung und Sprite-Richtung bleiben getrennt.
- **Ring:** 44 grüne, gleichmäßig verteilte Wasserpunkte `#31E65D` mit weißlich-hellen Kernen und schwachem Halo. Ellipsenradien `max(38, length×0.53)` bzw. `max(18, length×0.215)`, der Wassermittelpunkt auf `ship_world_position.y + length×0.045`. Keine Gameplay-Kollision und keine Klickflächen im Ring.
- **Namenszeile:** Elfenbeinfarbener Spielername, goldenes Gildenkürzel, links Piratenrang/Staffrolle und rechts echte BP-Markierung. Dezente ID bleibt, gefolgt von grüner HP- und blauer Schildleiste ohne ausgeschriebene HP-Zahlen am Schiff.
- **Deckblock:** Mittelpunkt **51 native Pixel** unter dem Namen, `r=8×_plate_pixels()` statt der bisherigen 5,5. **Zwei deutlich größere Goldschädel** oberhalb einer **mindestens 25 Pixel großen echten Kanonenplatz-Zahl** aus `sim.cannon_slots()`. Symmetrische Kronen und filigrane Seitenornamente; unteres Schädelabzeichen. Zehn ausrüstungsabhängig gefärbte Deckpunkte als **zwei Reihen zu fünf**. Die Zahl ist ausdrücklich nicht die frei erfundene 656 aus dem Referenzbild.
- **Sonderdecks:** drei unterschiedliche eigene Vektor-Piktogramme im selben Ornamentrahmen: **Gezeiten (Wellen links), Sturm (Blitz rechts), Bergung (Anker unten)**. Die Leuchtdarstellung richtet sich nach den **tatsächlich aktiven Buff-Zeiten**. Kristallsegen bleibt eine eigenständige Anzeige.
- **Mobil:** Gesamter Namens-/Status-/Deckblock hat eine stabile native Screen-Space-Darstellung. Mobile Kampf- und Schnellbuttons dürfen den erweiterten Block nicht überdecken. Das Gameplay-Feld wird nicht statisch verkleinert, der HUD-Layouttest prüft reale 852×393, 844×390 und 720×405.

Die Veröffentlichung erfordert: Godot-Tests, alle aus den Source-GLBs neu erzeugten Sprites, WebGL2-Teststart **und Sichtprüfung der frisch gerenderten Captures**. Keine Freigabe allein aufgrund von erfolgreichem Commit oder PR.
