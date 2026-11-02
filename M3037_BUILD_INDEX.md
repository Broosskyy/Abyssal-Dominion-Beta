# Abyssal Dominion – aktueller M303.7-Grafik-Testbuild

Stand: 29. Oktober 2026

## Aktueller erfolgreicher Android-Export

- Code-Branch: `rebuild/m3037-graphics-integration`
- Code-Commit: `7f90ca3369c2702b01cb17a90b9ddf415e625c1d`
- Zugehörige SeaBattles-/Sea-of-Bones-Grafiken: `rebuild/classic-seafight-m303`, Commit `344e5c855a23c90a887a132da07884db6811281f`
- Godot: `4.7.2`
- APK: `ABYSSAL_DOMINION_M303_7_GRAPHICS_TEST.apk`
- APK-SHA-256: `73d79b0e53f0599b8daba2c9403d52827199baf5c9cba85adbc648febacc2074`
- APK-Bytes: `76,070,200`
- GitHub Actions: https://github.com/Broosskyy/SOH-2/actions/runs/40960710903
- Download-Artefakt-ID: `12934959787`
- Artefakt-Link: https://github.com/Broosskyy/SOH-2/actions/runs/40960710903/artifacts/12934959787
- Ergebnis: Godot-Projektil-/Bewegungstests PASS; 59 Grafikprüfungen PASS; APK-ZIP/Sig/16-K-Alignment PASS.
- Android-Installation und sichtbare Qualität auf realem Gerät: **NOT_TESTED**.

## Bedeutung der GitHub-Sicherung

Der **Code** ist versioniert. Die extrahierten **Grafikpakete** befinden sich im älteren Grafik-Branch. Die **zusammengebaute APK** ist derzeit ein zeitlich begrenztes GitHub-Actions-Artefakt und **kein Git-Commit, Git-Tag oder dauerhafter Release**.

Das Artefakt wurde am 29.10.2026 erstellt und wird laut GitHub am **01.11.2026** gelöscht, falls es nicht separat gesichert wird. Mit der aktuellen Konfiguration sind nicht alle drei Lieferbestandteile als ein einziges dauerhaftes Versionspaket archiviert.

Der GitHub-Stand `main` (M302) wurde nicht überschrieben. Für eine dauerhafte Gesamtversion aus Code, Grafiken und APK ist eine private, geordnete Ablage erforderlich; fremde Testgrafiken gehören nicht in öffentliche Releases.

## Weiterentwicklung

Verbindlicher Integrationszweig für **neue** M303.7-Arbeiten: `rebuild/m3037-graphics-integration`. Änderungen dort nach jedem Meilenstein pushen und den GitHub-Actions-APK-Export prüfen. Wenn der ältere Grafik-Branch geändert wird, muss die APK ebenfalls neu gebaut und auf denselben Grafikstand bezogen werden.

**Nicht als aktuell bezeichnen**, wenn der letzte erfolgreiche APK-Build einen anderen Code-/Grafikstand verwendet.
