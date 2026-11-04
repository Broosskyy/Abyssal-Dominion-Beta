# M33 — Asset-Slots und UI-Platzhalter

## Konzeptbezug

Grundlage: wiedergefundene M32_PLAN.md vom 30.08.2026 und der M29-Prüfbericht,
jeweils vollständig gelesen, plus Nutzerkorrektur aus M32.
Eine separate eindeutig versionierte SeeFight-Masterdatei konnte nicht bestätigt werden.
Keine Übernahme von Abyssal- oder Loot-Launch-Regeln.

Umgesetzt ist ein begrenzter Teil des dort vorgesehenen Grafik-/Austauschbarkeitsabschnitts.
Die ursprüngliche native P0-Abnahme ist NICHT erledigt.

## Ergebnis

18 GLB-Slots: 14 aktiv angebunden, 4 vorbereitet (npc_shadow, wreck, cannon, buoy).
33 UI-Slots: sechs vorhandene plus 27 neue SVGs, davon 24 Icons, Porträt, Kartenrahmen
und Fokusgrafik. settings ist nur im Vorschautool; andere Icons können Menüs für
noch fehlende Onlinefunktionen kennzeichnen und sind kein Nachweis solcher Dienste.

VisualAssetCatalog lädt Status/Verbraucher und separat editierbare Overrides.
AssetVisualLibrary verwendet einen separaten visuellen Unterbaum; maßstäbliche
Grundflächenanpassung und explizite Transformationen verändern keine Gameplaydaten.
NauticalTheme, Einstieg, HUD und Arsenal binden die neuen UI-Dateien ein.
Bisherige Unity-Icons im HUD-/Arsenalpfad sind durch eigene SVGs ersetzt;
nicht sämtliche Referenztexturen oder Audiodateien im Gesamtprojekt wurden ersetzt.

Die Einzelvorschau lädt alle 51 Slots, zeigt Quellpfad/Status sowie für Modelle
Bounds und Wasserlinienmarker. Keine neue Spielsimulation, keine Speicherzugriffe.
Die UI-Kontaktübersicht zeigt Assets, keinen Screenshot des Spiels.

## Tests

Nachweis in m33_current_validation.json, zugehörige Logs und m33_asset_audit.json.
M30-, M31- und M32-Suiten bleiben Regressionen; neue M33-Suite prüft alle GLBs/UI-Dateien,
Meshdaten, Statusangaben, Texturcache, das Vorschautool sowie Grafiktausch am echten Spieler-Wrapper.
Tauschtest: Hafen-GLB statt kleinem Schiff, bewusst völlig andere Geometrie.
Kollision/Shape-Ressource, Kanonen-Sockets, HP, Schaden, Fortschritt und Inventar bleiben unverändert.
Zusätzliche Prüfung für Transformationen, Rückfall, UI-Zuordnung und Nine-Slice-Ränder.

Im ersten Test wurde ein Namenskonflikt von reload() mit Godots Script-Ressource gefunden;
die Katalogfunktion heißt deshalb explizit reload_catalog(). Der abschließende Lauf ist maßgeblich.
Der separate SVG-Kontaktbogen wurde als Rasterbild zur Sichtprüfung der Grafiken angesehen.
Das ist keine Abnahme von Godot-UI-Layout oder 3D-Grafik auf einer GPU.

## Grenzen

Die 18 GLBs sind unverändert stilisierte Platzhalter, keine neu detaillierten Hero-Modelle.
Keine neue Hafenburg, keine finalen Animationen/LODs, keine komplette 20er-Hauptdesignreihe.
Wasser, Brandung, Kielwasser, VFX, Audio, gezeichnete HUD-Rahmen/Minimap und weitere
Systemgrafiken sind noch nicht vollständig über den neuen Slot-Katalog austauschbar.
Keine gemessenen FPS-, Wärme-/Akku- oder GPU-Budgets. Keine 4.7.2-/Native-Geräte-Abnahme.
Nur ergänzende Godot-4.5.1-Headless-Tests; Zielversion bleibt 4.7.2.
Web bleibt Preview, native Windows/macOS/Android/iOS sind weiterhin Hauptziele.
