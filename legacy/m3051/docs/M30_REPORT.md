# M30 — Neuaufbau auf M29

## Implementiert

- Arsenal-Layoutschlüssel auch im Querformat; 3 bzw. 6 Navigationseinträge statt Überfüllung.
- 48-Pixel-Mindestgrößen der getesteten HUD-Aktionen, repositionierte Kampf-/Zoom-Bedienung.
- Native scrollbare Command-Deck-Seiten, keine manuellen Touch-Press-Menüaktionen mehr im aktiven Pfad.
- Gegenseitige Sperre von Command Deck, Arsenal und Journal; separate See-Einstellungen.
- Entfernte Home-Overlay-Schaltfläche, die zuvor die MENÜ-Aktion überlagerte.
- Kamera-Rad, Zoom-Empfindlichkeit, Recenter, Fokusverlust-/Touch-Abbruchbehandlung,
  Besitzerprüfung für vorgemerkte HUD-Touches.
- 18 GLB-Dateien und 6 SVG-Dateien; zentraler Grafiktausch, Original-Referenzmodus erhalten.
- Monsterprofil vor verzögerter Schiffsgrafik geschützt; Wasser-Normalen korrekt dekodiert/gemischt.
- Grafikprofil, FPS-Limit, Renderfaktor, Schatten, VSync/Vollbild wo unterstützt;
  Master-/Meeres-/Kampfaudio; Kamera und Name-/Balken-/Schadensanzeigen.
- Reduzierte Wasser-/Kamerabewegung und abschaltbare Mündungsblitze. Keine pauschale
  Photosensitivitäts-Zertifizierung: andere Effektarten sind damit nicht vollständig deaktiviert.
- Echtes Gold/Munition statt erfundener Diamanten; aktive Menüs kennzeichnen Offline-Funktionen.
- Konfigurationsversion 0.30.0, sichtbarer M30-Titel; tatsächliche Speicheridentität M28 bleibt.
- Web-Import endet mit `--quit`; Exportfilter enthalten das Asset-Manifest.

## Verifikation

`tools/check_m30.py`: GLB-Dateilänge/Hash, Godot-Import, aktuelle M30-Laufzeitprüfung.
Die Ergebnisse sind in `m30_current_validation.json` und den Import-/Runtime-Logs abgelegt.
Geprüfte HUD-Größen: 844×390, 1280×720, 1920×1080, 390×844, jeweils mit versetzter Safe Area.
Zusätzlich: Asset-Wechsel ohne Colliderverlust, Katalog-Laden, Menüseiten, Audio-/Renderwerte,
Profil-Einstieg, Einstellungen von See, Heimkehr, gespeicherte Settings und Korruptionsschutz.

Nur ergänzende Headless-Prüfung mit installierter 4.5.1. Ziel 4.7.2 bleibt ungeprüft.
Keine neuen Ingame-Screenshots, keine GPU-Visualläufe, keine Android-/iOS-/macOS-Abnahme.
Bestehende M10–M29-Berichte sind historische Belege und keine aktuelle Freigabe.

## Nicht enthalten / nächste Entscheidung

M31 wird nicht vorweggenommen. Keine neuen Onlinekonten, Server, Kalender-Resets,
Ship-Level-/Loadout-Progressionssysteme oder M32–M35-Implementierungen.
Für den nächsten Schritt zuerst M30 visuell mit bestätigter Zielengine und Zielgeräten prüfen;
danach M31-Inhalte planen. Detailgrad und Ähnlichkeit zum Mockup sind noch kein Abnahmestand.
