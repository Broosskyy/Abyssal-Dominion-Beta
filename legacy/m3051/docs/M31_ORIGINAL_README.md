# SeeFight 3D — M31

Version 0.31.0, neu auf dem vollständig geprüften M30 aufgebaut.
Lokaler Rekonstruktions-/Testclient; kein offizieller Spielserver.

## Start

`project.godot` im Godot-Editor importieren und starten.
Splash → lokales Profil oder Gast → Starterwahl → ZUR SEE.

Die Projektvorgabe bleibt 4.7.2. Hier wurde nur mit der vorhandenen
**Godot 4.5.1 stable ergänzend headless getestet**. Kein Nachweis für die
Zielengine 4.7.2, native Exporte, GPU-Qualität oder reale Geräteperformance.
Windows/macOS/Android/iOS bleiben Hauptziele; Web dient nur der Preview.

## Neu in M31

- Drei Starter zur einmaligen kostenlosen Auswahl bei neuem Spielstand.
- Schiffslevel 1–10 mit eigenen XP und Verbesserungen pro Design.
- A/B-Ausrüstung inklusive Waffenmodus pro Schiff gespeichert.
- Erste Piratenprüfung; Belohnung, Green Frontier und AUTO-Freischaltung.
- Zielgebundene Kanonensalven; Harpunen gegen Monster.
- Gleicher Trefferschaden unabhängig von der Schiffsausrichtung;
  geschützte Ziele, Reichweite, Munition, Reload und Hindernisse werden geprüft.
- Tageswechsel um 00:00 UTC, Wochenwechsel Montag 00:00 UTC.
- Lokale 15-Minuten-Jagd mit Jagdmarken und Reparaturangebot im Hafen.
- Korrigierte JSON-Prüfsummen; kompatibles Lesen alter Speicherdateien;
  Schutz beschädigter Dateien und intakter Backups.
- M30-Grafikbasis, Kamera-Rad, Touch-Menüs und Systemeinstellungen bleiben erhalten.

## Spielabschnitt

1. Starter auswählen. Gegner auf See antippen und FEUER nutzen; Beute einsammeln.
2. Ab Piratenlevel 2 im Hafen unter MENÜ → Markt den Rumpf einmal verbessern.
3. Unter MENÜ → Fortschritt & Prüfung den Versuch im Hafen starten.
4. Danach 3 Gegner besiegen, 2 Beuten sammeln und einen neuen Hafenbesuch abschließen.
5. Prüfung im Hafen abgeben: 300 Gold, 120 XP, Green Frontier und AUTO.
   Sinken beendet den laufenden Versuch; ein Neustart im Hafen ist möglich.

Kanonen/Harpunen unter Arsenal oder MENÜ → Waffen & Loadouts auswählen.
AUTO verfolgt kein Ziel und fährt nicht selbstständig hinter Gegnern her.
Weitere Seekarten sind für neue Profile noch nicht Teil dieses Abschnitts;
alte M30-Spielstände behalten ihren bisherigen Kartenzugang.

## Dateien und Prüfungen

- `docs/M31_REPORT.md`: Umsetzung, Migrationsregeln und offene Grenzen.
- `docs/m31_current_validation.json`: aktuelle Prüfung, verwendete Engine.
- `docs/M30_ASSET_SWAP.md`: GLB-/UI-Austausch. Die Harpune ist in M31 aktiv angebunden.
- `docs/M32_NEXT_STEPS.md`: nächste Abnahmeschritte.

```sh
python3 tools/check_m31.py --engine /pfad/zu/godot
# Ergänzender Lauf mit einer anderen Engine, ausdrücklich so gekennzeichnet:
python3 tools/check_m31.py --engine /pfad/zu/godot --supplementary
python3 tools/package_m31.py /ausgabeordner
```

Web-Preview: `python3 tools/preview.py --godot /pfad/zu/godot` bzw. `npm start`.
Benötigt die vorgegebene Engine und passende Export-Templates. Kein vorgebautes
M31-Web-Spiel enthalten, kein Auth-/Multiplayer-Server.

## Grenzen

Lokale Profile ohne Passwort; Gast ohne Speicherung. UTC basiert auf der Geräteuhr,
nicht auf einem vertrauenswürdigen Server. Jagddauer/Pause zählen aktive Spielzeit.
Die Jagd ist ein lokaler Aktivitätstest, kein vollständiges weltveränderndes Event.
Keine neuen finalen Grafik-Assets, keine 1:1-Grafik zum Mockup, keine Online-Ranglisten
oder Crossplay-Implementierung. Native visuelle Abnahme steht weiterhin aus.

Alle Laufzeit-Assets sind enthalten. Das M30-Referenzarchiv bleibt unverändert optional.
Historische Berichte belegen nicht den jetzigen Stand. Speicheridentität M28 nicht
umbenennen: Anzeige/Version sind M31, der bisherige Spielstandordner bleibt erhalten.
