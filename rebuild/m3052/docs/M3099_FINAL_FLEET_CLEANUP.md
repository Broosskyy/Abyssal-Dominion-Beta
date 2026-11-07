# M3099 — Finaler Schiffs-/Grafik-Cleanup (Update 137+)

## Verbindlicher Produktionsumfang
- **Ein einziges Spielerdesign:** Schattenkriegsschiff in der optimierten **SHADED-GLB**-Variante (`assets/player/schattenkriegsschiff_shaded.glb`).
- **Neun zugelassene NPC-GLBs:** unveränderte Originalmodelle unter `assets/npc/meshy/models/`. Ihre vorhandene Zuordnung zu 16 NPC-Spawnplätzen und das Seeungeheuer bleiben bestehen.
- **Nur zwei Grafikmodi:** `hybrid` = 2,5D mit echten GLBs, 40° Kamera; `3d` = dieselben echten GLBs mit 48° Kamera. Wasser und Gameplay bleiben 2D. Kein Classic-/Sprite-Modus.
- Die bisherigen A/B/C-/Original-/PBR-/Shaded-Vergleichsschalter, alter Gemi11-Test und alle mehrfachen Werft-Designs werden entfernt.
- In der Werft gibt es nur noch ein aktives, nicht austauschbares Schiff; die UI kann weiterhin Waffen, Ausrüstung und Munition verwalten.

## Physisch aus dem aktiven Git-Stand entfernt
- Alle alten Test-GLBs und 2D-Achtansichten, einschließlich Gemi11/Crimson/Test 2/A/B-Vergleiche. Das eine shaded GLB wurde **ohne Binäränderung** an den finalen Ressourcenpfad verschoben.
- Alle zehn frühen User-Schiff-Texturen, zwölf Fleet- und vier Referenz-Schiffsatlanten, beide alte Starter-Sheets sowie die zugehörigen Schiffs-Metadaten und Manifestdateien.
- Obsolete Import-Workflows und Quell-ZIP-Archive für frühere Schiffsvarianten.
- Die originalen neun NPC-GLBs, Karten, Inseln, Monster, HUD-Symbole, Munition, Ausrüstung, Gameplay-Code und das Android-Updater-Bootstrap bleiben erhalten.

## Save- und UI-Migration
- *Jede* bisher gespeicherte Skin-ID (0–30, inklusive Gemi11 und historischem Einsteigerschiff) wird beim Laden auf die einzige gültige ID 0 abgebildet. Andere Save-Felder (Gold, Level, HP/Schild, XP, Käufe, Decks, Quests, Schiffsposition, Karte) werden nicht aufgrund des Designwechsels verändert.
- Alte Render-Präferenz `classic` wird zu `hybrid`; `3d` bleibt `3d`. Alte `test_visual_style`-Einträge werden ignoriert und beim nächsten Speichern der Anzeigeeinstellungen nicht mehr geschrieben.
- Für Zielporträts nutzt das HUD bis zur Erstellung echter NPC-Vorschaubilder ein neutrales nautisches Symbol statt alter, fremder Schiffsatlanten. Die NPC-Schiffe selbst bleiben echte 3D-GLBs.
- Werft und Schiffsdialog erhalten eine einzelne Vorschaugrafik als kleines UI-Asset. Diese ist kein separates Spielmodell.
- Automatische Tests kontrollieren genau einen Spieler-GLB, neun NPC-GLBs, gelöschte Altdesigns, beide Modi und alte Speicherstände. Das Datenpaket wird wie bisher signiert und separat über den Updater verteilt.

## Sicherung und technische Grenzen
Die Löschung betrifft den **aktuellen Repository-Stand und die neu exportierten Spieldaten**. Bereits veröffentlichte historische Releases und frühere Git-Commits werden nicht rückwirkend vernichtet; dazu wäre eine separate, riskante Git-History-Umschreibung nötig, die ausdrücklich nicht vorgenommen wurde. Die Legacy-Quellarchivierung bleibt getrennt vom aktiven Godot-Projekt.

Die finale GLB hat dieselbe originale Binärgeometrie wie zuvor (die 14-%-Heckkorrektur erfolgt weiterhin zur Laufzeit). Die neue 3D-Kamera muss auf Android visuell überprüft werden; automatisierte Godot-/Signaturtests ersetzen keinen Gerätetest.
