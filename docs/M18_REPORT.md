# M18 — Kapitänsbuch, Hafenübersicht und Zielauswahl

Implementierte Fortsetzung von M17 mit **Godot 4.7.2 stable**, Projektversion
**0.18.0**. Keine Übergabe als Arbeitsauftrag an einen anderen Editor.

## Oberfläche und Spielablauf

Das neue native Kapitänsbuch übernimmt die dunkelblaue/goldene Richtung des
Nutzer-Mockups. Die Missionskarte ist jetzt ein echter Button. Sie öffnet eine
scrollbare Auftragsseite mit aktiver Aufgabe, den beiden folgenden Aufgaben,
Fortschrittsbalken, Gold-/EXP-Belohnungen und Abschlusszahl. Die drei vorhandenen
Missionstypen werden dargestellt, kein umfangreicher neuer Questkatalog erfunden.

Der zweite Reiter ist die Hafenübersicht. WERFT im oberen HUD öffnet diesen
Reiter. Hafenname, Rumpf, Gold, Eisenmunition und Reparaturvorrat stammen aus dem
laufenden Spiel. Anlegen delegiert an die vorhandene PortInteraction: Reparatur,
Grundversorgung, Wiederkehrpunkt und Öffnen der bisherigen Werft. Versorgung
öffnet das vorhandene Arsenal; dessen echte Kaufbedingungen gelten unverändert.
Anlegen außerhalb der Nähe eines registrierten Hafens bleibt gesperrt.

Native Labels/Buttons werden einmal angelegt und bei sichtbarem Buch alle
0,2 Sekunden aktualisiert. Keine Neuerzeugung der Karten bei jedem Bild.
Tabs und Schließen bleiben außerhalb des Scrollbereichs, mindestens 48 Einheiten
hoch. Prüfung bei 1280×720, 844×390 und 390×844.

## Missionen und Integrität

- Ein Abschlussereignis meldet die tatsächlich ausgezahlten Gold-/EXP-Werte.
- HUD-Log und Buch zeigen den Abschluss; kein zusätzlicher Abholen-Button und
  keine zweite Auszahlungsfunktion.
- Automatische Folgeaufgabe, Zähler und bisheriges Save-Format bleiben erhalten.
- Die letzte Abschlussmeldung ist sitzungslokal. Laden eines Spielstands
  erzeugt keine Belohnungsmeldung und keine neue Auszahlung.
- Dock-Aufgaben verwenden weiterhin den vorhandenen Schutz gegen mehrfaches
  Zählen desselben Hafenbesuchs.

## Eingaben und Zielauswahl

Das Buch stoppt Navigation und eigenes Dauerfeuer. Bewegung, Schuss, Reparatur,
Boost, Karten- und Arsenal-Hotkeys greifen nicht durch das offene Buch hindurch.
ESC schließt es. Ein kurzer 150-ms-Eingabeschutz verhindert, dass die Taste zum
Aktivieren des Schließen-Buttons zusätzlich einen Schuss auslöst. AUTO startet
beim Schließen nicht von selbst erneut.

Die Welt läuft weiterhin; das Buch ist keine globale Pause und verleiht keinen
Schutz. Bei Versinken des eigenen Schiffs wird es geschlossen.

Zielauswahl prüft zuerst einen Physikstrahl gegen Körper auf Kollisionsmaske 1.
Der eigene Rumpf und reine Areas werden ausgenommen. Der erste fremde Rumpf
gewinnt vor Schiffen dahinter; ein Insel-/Pier-Körper blockiert die Auswahl.
Nur wenn der Pointerstrahl nichts trifft, bleibt die 36px-Näheauswahl aus M17 als
Touch-Hilfe erhalten. Auch diese prüft nun die Sichtlinie zum Zielanker.

Grenze: Es sind die vorhandenen **Kollisionsformen**, keine pixelgenauen Meshes.
Sichtbare Masten, Palmwedel oder andere Geometrie ohne passenden Collider können
abweichen. Auswahl über T bleibt eine gesonderte Zielliste; sie ist nicht dieselbe
Sichtlinienprüfung. Das ist keine neue automatische Wegfindung oder Hindernisumfahrung.

## Prüfung

| Prüfung | Ergebnis |
| --- | --- |
| Godot 4.7.2 Import und M10–M18-Suiten | 1.335 / 1.335 bestanden |
| Neue M18-Suite | 55 / 55 bestanden |
| Python Preview-Tests | 12 / 12 bestanden |
| Statische Plattformprüfung | 19 / 19 bestanden |
| Neuer Web-Build | erfolgreich mit passenden 4.7.2-Templates |
| Reale HTTP-Auslieferung | M18-Version, Quellhash, HTML und WASM-MIME bestätigt |
| Visuelle Abnahme | offen; Chromium nicht installiert |

Die M18-Suite prüft Native-Button-Aufruf, Layoutgrenzen/48px-Höhen, Tabwechsel,
Eingabesperren, Schließen ohne Schuss, konkurrierende Overlays, tatsächliche
Missionsrotation und Auszahlung, vorhandenes Save-Format, reale Hafenaktionen,
physische Verdeckung, Versinken und Szenen-Teardown. Keine alte fachliche
Assertion wurde für M18 abgeschwächt. Headless-Layouts sind keine Screenshots.

Nachweise: `m18_engine_validation.json`, zugehörige Logs,
`m18_http_validation.json`, `qa_m18/status.json`. Der Web-Quellhash steht zusätzlich
in `builds/web/preview-build.json`.

## Referenz- und Inhaltsgrenze

Die bereits in M17 dokumentierten Genre-Referenzen (Battle of Sea, Terror of Sea,
Legend Pirates) bleiben Kontext. M18 behauptet keine Übereinstimmung mit deren
Server-/Questlogik. UI-Komposition ist eigene Godot-Umsetzung des Nutzer-Mockups.

Keine neuen Originalassets extrahiert, keine neuen Schiffe/Inseln, keine große
Festung oder Kraken. Bestehende Werft-/Arsenal-Unterseiten wurden nicht komplett
neu gestaltet. Die M17-Truhen bleiben native Ersatzgrafiken. Keine Multiplayer-,
Online-Gilden- oder Echtgeldfunktionen, keine neuen signierten APK/IPA-Dateien.
Die alte M17-Ausgabe bleibt als Rückfallversion erhalten.
