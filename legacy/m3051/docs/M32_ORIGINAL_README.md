# SeeFight 3D — M32

Version 0.32.0 · Korrektur der Anfängerprogression auf Basis von M31.
Lokaler Rekonstruktions-/Testclient, kein offizieller Spielserver.

## Start

project.godot im Godot-Editor importieren und starten.
Splash → lokales Profil oder Gast → ZUR SEE. **Keine Starterwahl mehr.**
Neue Spielstände besitzen ausschließlich **Swift Barco**, das kleine Schiff.

| Abschnitt | Ergebnis |
| --- | --- |
| Start, Kartenlevel 1 | Kleines Schiff automatisch |
| Anfängerauftrag 1 abschließen | Mittleres Schiff Clipper + Kartenlevel 2 + AUTO |
| Anfängeraufträge 2, 3 und 4 | Kartenlevel 3, 4 und 5 nacheinander öffnen |
| Anfängerauftrag 5 abschließen | Großes Schiff Iron Chalupa + Kartenlevel 6 |
| Ab Kartenlevel 6 | Grenze zur späteren Elite-/Hauptdesignreihe; diese Flotte fehlt noch |

Die Reihenfolge klein → mittel → groß entspricht der Nutzerkorrektur.
Auftragsziele und Freischaltungen nach Auftrag 1 / 5 sind M32-Testwerte,
keine nachgewiesenen Originalregeln. Elite-Einstieg bei Kartenlevel 6 bleibt vorläufig.
Zentrale Werte: scripts/progression/beginner_rules.gd.

## So spielst du den Abschnitt

1. Hafen anlaufen/andocken. MENÜ → **Kartenfortschritt** → Auftrag beginnen.
2. Auf dem angegebenen **Kartenlevel** 3 Gegner versenken und 2 Beuten bergen.
3. Danach erneut einen Hafen anlaufen und andocken. Karten ohne Hafen verlangen
   eine Rückfahrt in ein bereits zugängliches Hafengebiet.
4. MENÜ → Kartenfortschritt → Auftrag im Hafen abschließen.
5. Freigeschaltete Schiffe in der Hafenwerft über AUSRÜSTEN wechseln. Kein Goldpreis.
   Neue Freischaltungen ersetzen das aktive Schiff nicht automatisch.

Jeder Auftrag gibt einmal 300 Gold und 120 XP. Der bestehende Piratenlevel-Bonus
kann zusätzlich anfallen. Sinken setzt nur den aktiven Auftrag zurück.
Piratenlevel (XP), Kartenfreigabe (Aufträge) und Schiffslevel (pro Design 1–10)
sind getrennt. Gold und XP umgehen keine Schiffssperre.
Kartenlevel sind nicht identisch mit der ersten Zahl historischer Kartennamen.

## Bestehende Spielstände

Besitz, aktives Schiff, Verbesserungen und A/B-Loadouts bleiben erhalten.
Vorhandene große Schiffe werden nicht weggenommen. Eine bestandene M31-Prüfung
zählt als Auftrag 1; ein fehlender Clipper wird ergänzt, ohne erneute Gold-/XP-Zahlung.
M30-Kartenzugang bleibt erhalten, zählt aber nicht als erledigte Anfängeraufträge.
Prüfsummen, Backup-Schutz und der bisherige Speicherordner bleiben bestehen.
Lokale Profile sind keine Onlinekonten; Gastmodus speichert nicht.

## Engine, Plattformen und Prüfung

Vorgabe: **Godot 4.7.2**. Hier nur ergänzende Tests mit **4.5.1 stable headless**.
Keine Abnahme für 4.7.2, native GPU-Qualität, Geräteperformance oder signierte Exporte.
Windows/macOS/Android/iOS bleiben Hauptziele. Web bleibt ausschließlich Preview.
GLB-Platzhalter, Touch-Steuerung, Grafik- und Systemeinstellungen bleiben erhalten.

Prüfen: python3 tools/check_m32.py --engine /pfad/zu/godot
Bei abweichender Engine zusätzlich --supplementary.
Paket erstellen: python3 tools/package_m32.py /ausgabeordner
Web-Preview: python3 tools/preview.py --godot /pfad/zu/godot oder npm start.
Benötigt Zielengine und passende Export-Templates. Kein vorgebauter Web-Export enthalten.

- docs/M32_REPORT.md: Umfang, Regeln, Migration und Grenzen.
- docs/m32_current_validation.json: tatsächliche Engine und Testergebnisse.
- docs/M33_NEXT_STEPS.md: ausstehende Gameplay-/Grafik-/Geräteabnahme.
- docs/M30_ASSET_SWAP.md: GLB-/UI-Austausch.

Historische M30/M31-Berichte sind keine aktuelle Abnahme. Keine neue finale Grafik,
keine vollständige Elite-Flotte, kein Online-Crossplay und keine 1:1-Mockup-Grafik.
Interne Speicheridentität M28 bleibt absichtlich bestehen; Anzeige und Version sind M32.
