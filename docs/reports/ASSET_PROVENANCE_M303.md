# M303 — Bildreferenzen und Asset-Herkunft
Recherche: 28.10.2026. Zweck: dokumentierte, rechtlich saubere Seafight-ähnliche Art Direction für Abyssal Dominion.

## Nachweisbare Quellen
1. **Originalspiel / Rechte-Kontext:** Bigpoint beschreibt Seafight als eigenes originales Piraten-MMO (https://www.bigpoint.net/seafight).
2. **Belegte Art-Produktion:** Natalie Hooge zeigte eigene „Ship concepts for Seafight“, ausdrücklich als Arbeiten für Bigpoint: https://nattlebattle.artstation.com/projects/qWNJN
3. **Weitere Konzept-Art:** Darek Zabrocki listet „Seafight-Battleship“ ausdrücklich als Mood Painting für Bigpoint GmbH: https://zabrocki.artstation.com/projects/R8Xr
4. **Öffentliche Designübersicht:** Offizielles Seafight-Forum führt zahlreiche Schiffsdesigns nach Namen/Kategorien: https://board-de.seafight.com/threads/schiffsdesigns.72018/
5. **Enginehistorie:** Eine offizielle Seafight-Community-Antwort bestätigt, dass 2021 die Unity-Version die frühere Flash-Version abgelöst hat: https://board-en.seafight.com/threads/todays-update-download.179994/ sowie https://board-en.seafight.com/threads/unity-patch-notes.179878/
6. **Screenshot-Referenzen:** Archivierte Seekarten/Isometrie bei Gamestar, offiziellen Forumsbeiträgen und Gamechannel; sie sind **Bildreferenzen**, keine Asset-Lizenz.

## Konkret: Woher könnten Ship, Island, UI und Ocean Assets des neuen SeaBattles stammen?
Die vom Nutzer beigefügten Play-Store-Aufnahmen von „SeaBattles : Pirate War“ zeigen ungewöhnlich nahe optische Ähnlichkeit zu historischen Seafight-Seekarten. Aus Bildähnlichkeit allein kann weder die Identität der Dateien noch deren Herkunft, Rechteklärung oder Herstellungsmethode nachgewiesen werden. Eine verlässliche öffentliche Asset-Liste des Entwicklers RoyaleGamesStudio wurde in dieser Recherche nicht gefunden. Möglich sind neu gerenderte 3D-Assets, handgemalte Sprites, lizenzierte Pakete oder tatsächlich reproduzierte Inhalte; **keine dieser Möglichkeiten ist belegt**.

### Seafight-Look gezielt und eigenständig produzieren
- **Schiffsdesigns**: Konzeptzeichnung -> eigener kompletter Blender-Ship-Mesh (Rumpf, Heck, Bug, Masten, Segel, Flaggen) -> Texturen/Materialien -> GLB in Godot. Alternativ feste Kameraposition + Render-Spritesheet (mit verschiedenen Schiffswinkeln und optisch stabiler Schattenrichtung). Eigenes Design mit klar unterschiedlichen Schiffssilhouetten/Fraktionen.
- **Inseln**: Separates Insel-Modell mit vollständigem Uferumriss, sandigem Übergang zum Meer, Klippen, Schnee/Pflanzen/Felsen und gestalteten Landmarken; feste Schiffs-/Inselgrößen relationieren; Kontur zur Navigation.
- **Meer**: shaderbasiertes großes nahtloses Ozeanfeld mit kleinen scrollenden Normal-/Lichtmustern, dezenter weißer Bugwelle, Küstenfoam. Kein einfarbiges PlaneMesh als Endgrafik.
- **UI**: eigene Navy/Gold/Antik-Holz-Materialsprache; Neun-Segment-Panels, unabhängige Buttons und hochauflösende Icons mit responsiven Abständen; Minimap, Nameplates, HP-/XP-Balken, Angriffs-/Munitionselemente. Bildlayout und Funktionshierarchie dürfen ähnlich sein; Texturen/Icons müssen eigenständig sein.
- **Art-Abnahme**: gleiche Bilddimensionen für Screenshot-Vergleich, gleiche Kamera-/Zoomposition, Schiffbreite in Pixeln, Inselgrößen und HUD-Bedienflächen numerisch vergleichen; auf Android quer und Browser testen.

## Rechtssicher beschaffbare Basis (keine fertige visuelle 1:1-Lösung)
- Kenney Pirate Pack: CC0, 190+ 2D-Top-Down-Sprites mit Schiffen/Land: https://kenney-assets.itch.io/pirate-pack
- Kenney Pirate Kit / Ship Medium: CC0 und GLB-Format; als 3D-Einstieg, nicht als Seafight-Endgrafik: https://flockbay.com/assets/ship-medium/
- Atomic Realm „Sea Assets – Ships“: 3D-Piratenschiffe, kostenpflichtig; konkrete EULA vor Produktion prüfen: https://atomicrealm.itch.io/sea-assets
- Kenney & Blender-Eigenproduktion sind Optionen; die M303-Szene verwendet zunächst bereits im Repository vorhandene 3D-Platzhalter, deren finale Qualität/Provenienz noch gesondert zu prüfen ist.

## Urheberrecht / Release-Gate
Keine Seafight/SeaBattles Grafiken, Clientpakete, Musik, NPC-Namen oder Originalsprites aus inoffiziellen Extraktionsarchiven in den distributierbaren Build aufnehmen. Auch „im Internet auffindbar“ bedeutet **nicht** frei nutzbar. Vor dem Release pro Asset: Autor/Quelle, konkrete Lizenz, Nachweis/Kaufbeleg, Modifikationsrecht, Weitergabebedingungen.
