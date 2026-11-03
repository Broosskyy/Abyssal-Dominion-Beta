# Small Starter mit acht intakten Richtungen

Status: erste integrierte Testfassung. Asset-ID SHIP-STARTER-001; Anzeigename Küstenschaluppe; gespeicherter Designindex 26. Neue Gäste beginnen damit, vorhandene Spielstände behalten ihre Auswahl. Auswahl im Hafen über Werft.

## Herkunft und Aufbau

PNG: rebuild/m3052/assets/generated/ships/starter_small_8_intact.png, 1774 × 887, echtes RGBA. Erzeugt mit integrierter Bildgenerierung, anhand des kleinen Schiffs der oberen Reihe von Abbildung 7 im hochgeladenen Masterkonzept V3.8. Die Seafight-Recherche dient dem Vergleich von Silhouetten und Richtungs-/Zustandssätzen; keine heruntergeladene Seafight-Grafik wurde als neues Runtime-Schiff eingebaut.

Die acht Bilder sind N, NE, E, SE / S, SW, W, NW. Sie zeigen den intakten Zustand. Ein Hauptmast, längs ausgerichtetes Hauptsegel und Vorsegel, Holzrumpf und gedämpfte blaue Leiste folgen dem Small-Starter-Brief. Die Darstellung ist eine generierte Näherung, keine mathematisch exakte Projektion eines 3D-Modells.

Alpha-gemessene Ausschnitte und geprüfte Wasserlinienpunkte stehen in assets/visuals/directional_overrides.json und ship_frames.json. Der Maßstab bleibt für alle Richtungen gleich; frontale Ansichten werden nicht künstlich auf die Breite einer Seitenansicht gestreckt. Die Richtungswahl nutzt acht Sektoren mit Hysterese. Ein zusätzlicher Save-Test prüft, dass Index 26 nicht auf ein älteres Design begrenzt wird.

## Abnahme und Grenzen

Die Galerie ships_page_3.jpg verwendet den echten sea_map._draw_actor-Renderer mit allen acht Richtungen und markierten Ankern. Der bestehende Fahrtest zeichnet zusätzlich einen Ost-West-Kurswechsel auf. Simulation, Progression, Grafikgeometrie und UI werden im Android-Build geprüft.

Diese Prüfungen ersetzen keinen physischen Android-Test und keine endgültige künstlerische Abnahme. Takelage, Deckdetails, Proportionen und Mastpositionen können zwischen generierten Ansichten noch leicht abweichen. Der eigentliche Starter-Freischaltpfad für Medium/Large ist nicht Teil dieser Änderung. Beschädigte Ansichten folgen separat; ein niedriger positiver HP-Wert wählt weiterhin eine intakte Ansicht.

## Erzeugungsprompt

```text
Use case: identity-preserve / 2D naval game sprite atlas.
Reference image is a production board with THREE rows of ships. Use ONLY THE SMALL SINGLE-MAST BOAT IN THE UPPER ROW as the style and construction reference. Ignore the middle and bottom rows completely.
Create exactly EIGHT views of ONE small beginner sailing sloop, for Abyssal Dominion starter ship 01. One transparent PNG atlas, four columns by two rows, one ship in each cell. The ship must be simple, mechanically plausible and physically identical in all views.
Locked construction: compact weathered brown wooden hull with a pointed bow, a short projecting bowsprit, low squared stern/transom, narrow muted dark-blue trim, a simple open deck, ONE vertical main mast at 45 percent of hull length from the bow, ONE modest cream gaff mainsail AFT of that mast, ONE small triangular cream jib between mast and bow. Small low stern locker, no tall cabin. One small plain dark-blue pennant. Restrained bronze fittings. No skulls, spikes, oars, rows of cannons, extra masts, giant ornaments, monsters or elite fantasy motifs.
CRITICAL: all eight sprites are a rigid yaw rotation of THIS same constructed sloop. Hull length/width, mast position, gaff/boom/sail shapes, bowsprit, stern locker and colors never change. Sails are FORE-AND-AFT sails, their planes stay roughly aligned with the ship's longitudinal axis and rotate WITH the hull. Their broad faces appear in east/west side views; north/south axial views show them narrow or overlapping. Never turn the sails independently toward the camera. No square-rig galleon sails.
Locked orthographic camera, elevated 50 degrees above the water plane, same elevation and same magnification in all eight images. Mast stays vertical on screen. Show decks consistently from above. North/south hulls naturally appear foreshortened; DO NOT enlarge them to match the projected width of side views.
Reading order MUST be:
top left: NORTH, bow toward top of screen, nearest end is the flat stern;
top second: NORTHEAST, bow up-right;
top third: EAST, bow right;
top fourth: SOUTHEAST, bow down-right;
bottom left: SOUTH, pointed bow and bowsprit nearest viewer, stern farther away;
bottom second: SOUTHWEST, bow down-left;
bottom third: WEST, bow left;
bottom fourth: NORTHWEST, bow up-left.
Distinct front and rear: the pointed bow and bowsprit ALWAYS opposite the flat stern and stern locker. Gaff sail always aft of the ONE mast. All intact, no damage.
Crisp painted game asset finish, strong readable silhouette at 150 pixels in gameplay, moderate detail, clean edge antialiasing, soft consistent neutral lighting without baked ground shadows.
Equal-sized invisible cells, a complete isolated sprite centered in each, generous space around all silhouettes, at least 10 percent clear margin between ships and cell edges. True transparent alpha outside ships. No sea, water, foam, wakes, shadows, terrain, labels, compass text, borders, grid, title, UI or watermark. Eight ships only.
```

## Geprüfter Build

- Version 0.305.5-test.2, Android-Code 305502, Paket com.abyssaldominion.rebuild.
- Source-Commit d79286ac38e78c0a4441cee4ac6b4955634fb73d.
- [Erfolgreicher CI-Lauf](https://github.com/Broosskyy/Abyssal-Dominion-Beta/actions/runs/41628517659).
- 951 Prüfungen erfolgreich: Simulation 22, Progression 63, Schiffsgeometrie/Richtungen 686, UI 180.
- 61 PNGs mit geprüften Kontrollsummen; 27 Schiffsquellen und 82 erfasste intakte Frames einschließlich der erhaltenen Originale.
- APK 38.549.876 Bytes, SHA-256 26abc3ba9c2ac36639c9bb1813d5a084ae2c56d052f23e3b2101aabeaeee9b31; Signatur und 16-KB-Ausrichtung bestanden.
- Acht Richtungen in der tatsächlichen Laufzeitgalerie angesehen. Eine Überschneidung von Bug/Richtungspfeil mit dem Schiffsnamen in der Südansicht wurde dabei entdeckt und in diesem Build korrigiert.
- Kontrollierte Ost-/West-Fahrbilder zeigen den Rumpf am logischen Auswahlpunkt. Die Bewegungsaufnahme und Galerie liegen unter releases/M3055/captures.
- Physischer Android-Test nicht durchgeführt. Beschädigte Richtungsbilder und Starter-Medium/Large-Freischaltungen bleiben offen.
