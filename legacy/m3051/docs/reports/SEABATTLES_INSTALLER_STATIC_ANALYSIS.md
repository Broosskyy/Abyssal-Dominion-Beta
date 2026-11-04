# Sea Battles Windows installer: statische Analyse (28.10.2026)

**Quelle:** vom Nutzer gelieferte `SeaBattlesInstaller.exe`. Die Datei wurde **nicht ausgeführt**. Keine Client- oder Backend-Verbindung hergestellt.

## Technische Befunde
- Größe: **150,584,808 Bytes** (143.61 MiB).
- SHA-256: `f3e9091cc9505053aae06e524070475a20591198c40a17d1bfa531221021e66f`.
- PE32, Windows x86 GUI, 5 Sektionen, Nullsoft/NSIS 3.03.
- NSIS-Datenanhang hinter PE-Sektionen beginnt bei Byte 112,640; komprimierter Archivbereich ungefähr 150 MB. NSIS-Header konnte mit raw DEFLATE statisch gelesen werden (Header-Länge 117,500 Bytes).
- Die Dateiliste im NSIS-Header bestätigt **Sea Battles Xsolla-Electron-Launcher** und enthält unter anderem:
  - `launcher.exe`, `LICENSE.electron.txt`, `LICENSES.chromium.html`, `chrome_100_percent.pak`, `ffmpeg.dll`, `resources.pak`.
  - `resources/app.asar`, `resources/config/launcher.json`, `app-update.yml`.
  - `resources/app.asar.unpacked/node_modules/@xsolla-launcher/launcher-core-win/bin/LauncherElectron.exe`.
  - Launcher-Komponenten `7za.exe`, `hpatchz.exe`, `torrent.dll`, `Qt5Core.dll`, `Qt5Network.dll` etc.
  - Produkt `Sea Battles`, Publisher `RoyaleGames, LLC`, Xsolla-Laufzeit/Registry-Bezüge.
- Sichtbare URLs im Zertifikatsanhang sind **DigiCert-Prüf-/CRL-URLs**, keine belegten Spiel-Download-URLs.
- NSIS-Header enthält Metrik-Endpunkt für Xsolla-Launcher-Installer; API-Schlüssel werden hier bewusst nicht dokumentiert oder verbreitet.
- Aus dem Installer-Archiv konnte **keine** eindeutige Unity-, Godot-, Unreal-Spielinstallation oder irgendeine Schiffs-/Insel-Spritebibliothek nachgewiesen werden.

## Schlussfolgerung / Grenzen
Der 143.6-MiB-Installer ist aller Wahrscheinlichkeit nach ein vollständiges **Launcher-Installationspaket**, nicht der tatsächlich spielbare Client. Electron/Chromium erklärt die Dateigröße. Die Engine, Schiffsmodell-/Spriteformate, Animationstechnik, Seekarten-/Renderinglogik und Assets des eigentlichen *Sea Battles*-Spiels lassen sich daraus **nicht** bestimmen. Die Bezeichnung „full installer“ bezieht sich in der statisch auslesbaren Launcher-Metadatenstruktur auf den Installer, nicht nachweislich auf einen vollständigen Game-Client.

## Sichere Folgeanalyse
1. Spiel über legitimen Hersteller-/Xsolla-Launcher installieren (nicht auf dem Analysecomputer ausführen).
2. Im laufenden Spiel Windows Task-Manager > Details > beim **Spielprozess** „Dateipfad öffnen“ (nicht nur `launcher.exe`).
3. Für eine reine Inventarisierung nur Verzeichnisbaum/Dateiformate übermitteln: beispielsweise `*_Data`, `UnityPlayer.dll`, `GameAssembly.dll` (Unity), `Content/Paks/*.pak`, `Engine` (Unreal), `.pck`, `.godot` (Godot) oder `.png`/`.atlas`/`.json` (2D-Atlas-Framework); Dateinamen allein beweisen keine Herkunft.
4. Erst danach die Art-Pipeline für unseren M303-Rebuild festlegen. Bis dahin `assets/classic/sprites/*16dir.svg` lediglich als eigene Ersatzgrafiken / Tech-Demo behandeln; **nicht behaupten**, SeaBattles verwende 2D-16-Richtungs-Sprites.
5. Drittanbieterdateien nur analysieren, nicht ungeprüft in den eigenen distribuierten Build kopieren; Lizenz und Rechte klären.

## Schutz
- EXE nicht ausgeführt.
- Keine fremden Client-Assets in GitHub committed.
- Keine aus dem Installer extrahierten Zugangsdaten übertragen.
