# M16 — Mockup-orientiertes HUD und Eingabeoptimierung

## Ergebnis und Herkunft

Implementierte Weiterentwicklung des vorhandenen M15-Godot-Projekts, kein Auftrag
an einen anderen Editor. Referenz ist das vom Nutzer gelieferte Bild `152969.png`.
Die unveränderte Referenzkopie unter `docs/reference/152969.png` enthält tatsächlich
JPEG-Daten. Der Dokumentationsordner ist vom Godot-Import ausgeschlossen; das Bild
wird nicht als HUD-Hintergrund oder Bestandteil der Spielszene eingesetzt.

Die Grafikrichtung wird nativ in Godot umgesetzt: dunkles Marineblau, Goldrahmen,
kompakte obere Statusleiste, Missionskarte links, kreisförmige Minimap rechts,
Steuerrad links unten, großes Feuer-Rad und kleinere Fähigkeits-/Munitionsräder.
Das ist eine Annäherung an das Layout, keine belegte 1:1-Rekonstruktion des Bilds.

## Umsetzung

- `NauticalLayout` liefert dieselben Rechtecke/Kreise für Zeichnung und Eingabe.
  Runde Aktionen verwenden kreisförmige Treffflächen. Desktop, kompaktes Querformat
  und Hochformat erhalten angepasste Positionen; getestete Aktionsflächen sind
  mindestens 48 × 48 Godot-Viewport-Einheiten groß.
- `NauticalHud` zeichnet das HUD ohne ein neues Control pro Anzeige. Ein wiederverwendeter
  Panel-Stil vermeidet StyleBox-Neuanlagen für jede einzelne Panel-Zeichnung.
  Bereits vorhandene rückgewonnene M11-Icons bleiben verwendet. Kettenmunition
  bekommt eine native Kettengrafik, weil kein passendes Original-Icon vorliegt.
- Anzeigen hängen an tatsächlichem Kapitän, Level/XP, Rumpf, Nachladefortschritt,
  Münzen, Munition, Missionen, Reparaturbestand und Boost-Abklingzeit.
  Das Protokoll hält höchstens drei lokale Aktionsmeldungen, keinen Online-Chat.
- Native Arsenal- und Menü-Buttons stehen in der oberen Leiste. Bestehende
  Arsenal-, Werft-, Karten- und Profilfunktionen bleiben erhalten. Nicht jeder
  Unterbildschirm wurde in diesem Schritt neu gestaltet.
- Projektion aller acht Ecken eines gecachten lokalen Modell-AABB positioniert
  Schiffsnamen und Balken außerhalb des Modells. Spieler bevorzugt darunter,
  Gegner darüber; seitliche Ausweichpositionen sind möglich. Gibt es keinen
  freien, HUD-freien Platz, wird die Anzeige ausgeblendet statt hineingequetscht.
- Kamera etwas diagonaler; Wasser blauer und Wellenhöhe reduziert. Spielersegel
  cremefarben, gegnerische Clipper-Segel rot, Flaggen dunkel. Diese Farben sind
  neue Gestaltungsentscheidungen, keine neu rückgewonnenen Originaltexturen.

## Eingabe

Freie See setzt per Maus/Touch einen Fahrpunkt; passive HUD-Flächen tun das nicht.
Der sichtbare Helm steuert per Touch. Feuer/Reparatur/Boost/Zielwechsel und die
drei Munitionsarten haben ausdrückliche Aktionen. Eine Aktion wird bei Wegziehen
oder Loslassen außerhalb abgebrochen. Ein Feuer-Finger während der Helmsteuerung
wird nicht als zweiter Zoom-Finger behandelt. Zwei Welt-Finger zoomen weiterhin;
das Ende der Zoomgeste startet keine Fahrt. Die Weltkarte stoppt die Navigation.
Bestehende Tastatur-/Gamepad-Belegung bleibt erhalten.

## Prüfung

| Prüfung | Ergebnis | Belegt nicht |
| --- | --- | --- |
| Godot 4.5.1 Import und M10–M16 Headless-Suiten | 1.114 / 1.114 bestanden | GPU-Bild, optische Gleichheit, Geräte-FPS |
| Davon neue M16-Prüfungen | 741 / 741 bestanden | Manuelle Bedien-/Lesbarkeitsprüfung |
| Python Preview-Tests | 10 / 10 bestanden | Browser-WebGL-Rendering |
| Aktueller Godot-Web-Export | gebaut, Quell-Fingerprint passend | Android-/iOS-Build oder Signing |
| Tatsächliche HTTP-Auslieferung | M16, aktuelles HTML, korrekter WASM-MIME-Type | Öffentliche Veröffentlichung |
| Browser-Screenshot-Versuch | blockiert: Chromium-Programm fehlt | Kein aktueller Screenshot vorhanden |

Layout-Fixtures: 1536×1024, 1280×720, 844×390, 915×412, 390×844.
Sie prüfen Aktionsüberschneidungen, Viewportgrenzen, Kreistreffer und Namensplatzierung.
Laufzeittests prüfen Navigation, passive Mission, gleichzeitiges Lenken/Schießen mit
echtem Munitionsverbrauch, Loslassen außerhalb, Munitionswechsel, Kartenumschaltung,
Pinch und native Arsenalposition. Headless zeichnet über den Dummy-Renderer und
ist ausdrücklich keine visuelle Abnahme.

Die M15-Flottenprüfung erwartet nun vier statt drei gemeinsam verwendete
Materialprofile für 20 Clipper (120 Mesh-Instanzen): Flaggen sind gegenüber Segeln
separat getönt. Das ist eine beabsichtigte Erwartungsänderung. Ein vorübergehender
Ressourcenhinweis beim Beenden war in der abschließenden Gesamtausführung nicht
mehr reproduzierbar; die Ursache wird nicht als behoben behauptet.

Nachweise: `m16_engine_validation.json`, `m16_hud_layout_validation.json`,
`m16_http_validation.json`, `qa_m16/capture_report.json` und zugehörige Logs.
Historische Bilder unter `qa_m12` sind keine M16-Screenshots.

## Bewusst offene Grenzen

Die große Festung, der Kraken, die detaillierten illustrativen Schiffsmodelle und
Schatzobjekte im Mockup sind hier nicht neu nachgebaut. Vorhandene rückgewonnene
Schiffs-, Insel- und Hafenmodelle bilden weiterhin die Szene. Kein fingierter
Gildenchat, Diamantenbestand oder Schutzschild-System wurde ergänzt.

Das Spiel bleibt offline; plattformübergreifende Exportvorlagen sind kein
fertiges Crossplay. Keine signierte APK/IPA, keine produktiven Accounts und kein
öffentlicher Spielserver. Vorhandene Login/Register-Funktion bleibt ein lokales,
passwortloses Profil. Save-Identität und Dateinamen bleiben absichtlich stabil,
auch wo historische Milestone-Kennungen enthalten sind.

Für optische Freigabe sind echte Desktop- und Mobile-Web-Aufnahmen sowie
Gerätetests nötig. Kamerawinkel, Materialtöne und Lesbarkeit müssen daran noch
abgeglichen werden. Die Rechte an Original-Testassets bleiben separat zu klären,
bevor das Projekt veröffentlicht wird.
