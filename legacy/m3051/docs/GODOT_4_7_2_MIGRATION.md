# M16 — Engine-Umstellung auf Godot 4.7.2

Projektversion: **0.16.1**, aufbauend auf M16 / 0.16.0. Kein neues Grafik-Milestone.
Tatsächlich ausgeführte Engine: `4.7.2.stable.official.ed1daf0bf`.
Die ursprüngliche M16-Ausgabe mit Godot 4.5.1 bleibt als Rückfallversion erhalten.

## Änderungen

- Projekt deklariert Godot 4.7; Build- und Testwerkzeuge verlangen exakt die
  stabile 4.7.2-Version, damit keine älteren Builds als neue ausgeliefert werden.
- GodotPhysics3D ist ausdrücklich gesetzt. Compatibility-Renderer, X/Z-Gameplay,
  Kamera, HUD, Assets, Profile und Spielstandsidentität bleiben erhalten.
- Passende offizielle 4.7.2-Single-Thread-Web-Templates installiert und verwendet.
  Das Hilfsskript zum Beschaffen dieser Templates wurde ebenfalls aktualisiert.
- Web-Preview komplett neu exportiert. Verpackung und HTTP-Prüfung prüfen jetzt
  zusätzlich die tatsächliche Engine-Version in den Nachweisen.
- Projekt-/Exportversion 0.16.1, Android-Code und iOS-Buildnummer 17.
  Alle sechs Exportvorlagen bleiben enthalten; keine neuen nativen Binärpakete.
- Im M15-Test wird nach dem Entfernen der Testszene 0,2 Sekunden auf die
  Ressourcenfreigabe gewartet. Zuvor kam sporadisch ein Exit-Ressourcenfehler vor.
  Der Hinweis blieb anschließend in der Gesamtsuite und drei Einzelwiederholungen
  aus. Audio-Worker-Timing ist eine mögliche Erklärung, kein bewiesener Engine-Bug.
  Fachliche Assertions wurden für diese Migration nicht abgeschwächt oder entfernt.

## Verifikation

| Prüfung | Ergebnis |
| --- | --- |
| Frischer Import und M10–M16 Engine-Suiten unter 4.7.2 | 1.114 / 1.114, alle Stufen bestanden |
| Preview-Unit-Tests einschließlich Versionsschutz | 12 / 12 bestanden |
| Statischer Plattformvertrag | 19 / 19 bestanden |
| Web-Debug-Export mit 4.7.2-Templates | erfolgreich |
| Tatsächliche lokale HTTP-Auslieferung | aktuelle Version/Quellhash, HTML und WASM-MIME bestätigt |
| M15-Test wiederholt | 3 × 47 / 47 ohne Exit-Ressourcenhinweis |

Web-Quellhash: `57652e5956b37c1e2086669554c45421d3aecc909142070598349ff04875175d`.
Nachweise: `m16_engine_validation.json`, zugehörige Engine-Logs,
`m16_http_validation.json`, `m5_platform_validation.json` und
`builds/web/preview-build.json`.

Der historische `M16_REPORT.md` beschreibt die vorherige 4.5.1-Ausgabe.
Die hier aufgeführten Nachweise ersetzen dessen Versionsangaben für dieses Paket;
historische Rekonstruktionsberichte werden nicht rückwirkend umgeschrieben.

## Start

Godot 4.7.2 **Standard**, Compatibility-Renderer, `project.godot` öffnen.
Für eigene Exports müssen die Export-Templates ebenfalls **4.7.2** sein.
Für die bereits gebaute Web-Preview genügt weiterhin `npm start` oder
`python3 tools/preview.py` im entpackten Projektordner, dann localhost:8077.
Der lokale Preview-Server ist kein Multiplayer-Spielserver.

## Grenzen

Headless-Tests und HTTP-Auslieferung sind keine Bildschirm- oder Geräteprüfung.
Kein neuer 4.7.2-Screenshot, keine Behauptung optischer Originaltreue oder höherer
FPS. Der frühere Browseraufnahme-Versuch in `qa_m16` gehört zur 4.5.1-Ausgabe und
war wegen fehlendem Chromium gescheitert. Hier wurde keine Browseraufnahme erstellt.
Android-/iOS-Installation, Signing und Desktop-Pakete müssen separat geprüft werden.
Crossplay bleibt wie zuvor vorbereitet, nicht fertig implementiert.

## Downloadherkunft und Nachvollziehbarkeit

Engine und Templates über die [offizielle 4.7.2-Downloadseite](https://godotengine.org/download/archive/4.7.2-stable/).
Abgeglichen wurden die offiziellen Migrationshinweise
[4.5 → 4.6](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html)
und [4.6 → 4.7](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html).

Lokale SHA-256-Prüfsummen zur Reproduzierbarkeit (keine unabhängige Signaturprüfung):

- Linux-Engine-ZIP: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`
- Web-Debug-Template: `08962aefef811b603541d7951ac67ef00413aad2d978855183c28adee98f626a`
- Web-Release-Template: `d3ee2f08cef0cf3cf6678a6355a92a8db48ccdd35cbd2e8bfd5f0e8a0b4032a0`

Die Engine selbst und vollständige native Export-Templates sind nicht im
Projekt-ZIP enthalten. Der direkt startbare Web-Build ist enthalten.
