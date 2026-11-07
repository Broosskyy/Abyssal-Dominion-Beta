# M3098 — Schiffsoptik nach Android-Videovergleich

Die Android-Aufnahmen nach Datenpaket 135 zeigen sowohl `TEST · Schattenkriegsschiff` (Skin 29) als auch `TEST 2 · Gemi11 UV korrigiert` (Skin 30) im echten 3D-Modus. Folgende rein visuelle Anpassungen wurden implementiert:

- **Schiffsgrößen:** Beide Testhüllen erhalten die gleiche sichtbare Längenvorgabe 158; andere Schiffsdesigns behalten ihre Maße.
- **Wasserlinie:** Skin 30 nutzt wie die optimierten B/C-Modelle 23 % Quellenhöhe als Referenz zur Kiel-Eintauchung. Modell, UV-Layout und ursprüngliche GLB-Datei bleiben unverändert.
- **Seafight-artiger Auswahlkreis:** Bei Spieler-Schiffen statt 0,55 nun 0,44 der visuellen Länge als horizontaler Radius, vertikal 0,185; die 3D-Kreismitte leicht zur Schiffs-Wasserlinie versetzt. Leuchtkonturen dezent reduziert, feindliche Markierungen/Simulation unangetastet.
- **Namen:** Spielerschiffsdesigns werden vollständig einschließlich Staff-/Gildenpräfix gerendert; Schriftgröße passt sich von 16 bis 12 an Bildschirmbreite und Badge-Länge an. Für NPCs bleibt die kompakte Ellipsen-Kürzung erhalten. ID, HP/Schild und Deckpunkte bleiben an ihren Positionen.
- **Gemi11-Textur:** Da die Quell-Albedo sehr dunkel ist, wird beim Instanziieren nur für Gemi11 ein StandardMaterial3D dupliziert, dessen Albedo-Textur als milde Eigenbeleuchtung verwendet wird (0,44). Beim originalen Schattenkriegsschiff dezenteres 0,17. Keine Textur neu gemalt und keine globalen Änderungen der NPC-Beleuchtung; B/C PBR-Shaded behalten ihre bisherigen Einstellungen.
- **Akzeptanztests:** tatsächliche GLB-Instanz und per-instance-Material, kreisförmige Dimensionen, gleichbleibende Schiffsausrichtung, vollständige Namen, Speicher- und Renderer-Kompatibilität.

**Grenzen:** Das Material verstärkt vorhandene Texturdetails, kann in der Ursprungsdatei fehlende Details nicht rekonstruieren. Ein visueller Vergleich auf einem echten Android-Gerät bei konstantem Zoom ist weiterhin notwendig. Diese Änderung ist nur kompatibler Spieldaten-Inhalt, kein neues APK-Installationspaket.
