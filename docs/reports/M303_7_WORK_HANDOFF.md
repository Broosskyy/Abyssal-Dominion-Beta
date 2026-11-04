# Abyssal Dominion M303.7 – Fortsetzung aus unterbrochenem Work-Run

**Status 2026-10-29:** Quellcode auf `rebuild/classic-seafight-m3037` committed. Kein native Godot- oder Android-Abnahmetest in dieser Umgebung möglich (Container/Python `ClientError`). Keine neue APK erzeugt, kein neuer Web-Build. `main` und `rebuild/classic-seafight-m303` unverändert.

## Gesicherter Basispunkt
- Ausgangscommit M303.6 `f7789a66cc51a0877b7aafebce15858df57b08e4`.
- Abzweig: `rebuild/classic-seafight-m3037`.
- Aktiver Godot-Projektstand: `project.godot` Version `0.303.7`, Szene `scenes/classic/classic_sea_map.tscn`.
- Neue Implementierung: `scripts/classic/m3037_combat_sea_map.gd` erweitert `m3036_unified_sea_map.gd`; kein Neuaufbau von Welt, UI oder Grafikpaketen.

## Was im Code geändert wurde
1. **Spielerfeuer:** 3D-Projektil für Kanone/Harpune mit dynamischer Position bis zum Ziel, vorangehendem Mündungsrauch und Einschlag. Die Munition geht beim Schuss ab, HP erst beim Eintreffen. Das verhindert ein unsichtbares Sofort-Treffen.
2. **Schadensfeedback:** Einschlag-Sphäre, kurz eingeblendete schwebende Schadenszahl, HP- und Gegnernamensanzeige, kurze Sinkanimation nach HP=0, bisheriges Gold-Beuteobjekt bleibt.
3. **NPC-Angriffe:** Gegner innerhalb von 23 Welteinheiten feuern jetzt sichtbare Geschosse, statt den Spieler-Rumpf sofort unsichtbar zu beschädigen.
4. **Schiffsmotor:** Auf den Wegpunkt eindrehen und entlang der tatsächlichen Bugrichtung fahren; Geschwindigkeit nach Winkel und Abstand begrenzt. Kein direktes Verschieben seitlich zum Wegpunkt.
5. **Kamera:** Näherer Zoom bis `34.5` statt zuvor `44.0` (ca. 22 % näher), auch für Magnify-Gesten; Standardzoom bleibt 82.
6. **Grafiksystem:** SeaBattles/SeaOfBones-Testgrafiken bleiben getrennt und austauschbar. Projektile liegen außerhalb des austauschbaren Schiff-Visuals, so dass der Wechsel während eines Schusses keine laufenden Treffer löschen soll.
7. **Regression:** `tests/m3036_unified_smoke.gd` instanziiert explizit die alte M303.6-Skriptklasse und prüft weiterhin deren bisherigen Sofortschaden. Neue Mechanik separat in `tests/m3037_combat_smoke.gd`.

## Was geprüft wurde
**PASS (nur Quelltext-/GitHub-Struktur, kein Engine-Test):**
- Neue Skriptdatei ist auf GitHub abrufbar.
- Aktive Szene zeigt auf M303.7.
- `project.godot` trägt Version 0.303.7.
- Neue `_sail`, `_fire`, `_enemy_attack`, `_zoom_in`-Überschreibungen und Effekt-Callbacks sind vorhanden.
- Testskript enthält verzögerte Treffer, NPC-Schuss, Grafikwechsel, Zoom und Bugrichtungsbewegung.
- Keine doppelten Funktionsdeklarationen im neuen M303.7-Skript.

**NOT_TESTED:** Godot-Parser, native FPS, 3D-Rendervorschau, echte Touch-Interaktion, Android-APK-Installation und Web-Browser-Gameplay. Bitte keine PASS-Aussage daraus ableiten.

## Verbindliche nächsten Befehle für Work

Zuerst `git fetch` und `git checkout rebuild/classic-seafight-m3037`, lokalen M303.7-Code nicht durch den älteren M303.6-Branch überschreiben.

1. `godot --version` → exakt Godot 4.7.2 nachweisen.
2. `godot --headless --path . --editor --import --quit` → Import-/Parserfehler beheben.
3. `godot --headless --path . --script res://tests/m3036_unified_smoke.gd` → alte Baseline.
4. `godot --headless --path . --script res://tests/m3037_combat_smoke.gd` → Flugzeit, HP, Schiffsbewegung, NPC-Geschosse, Grafikzustand.
5. Test mit privaten Paketen und Engine-/Browser-Laufzeit durchführen: `assets/classic/private_seabattles`, `assets/classic/private_seaofbones`. Wenn die Pakete fehlen, klare Fehlermeldung statt unbemerktem Fallback.
6. `tests/m3036_visual_capture.gd` mit `M3036_CAPTURE_DIR` für 844×390, 1280×720, 1920×1080 ausführen; neue Screenshots im tatsächlichen M303.7-Spiel zeigen.
7. Gameplay-Test (mindestens 30 Sekunden) aufzeichnen: fahren, drehen, Ziel auswählen, Projektil fliegt, Einschlag, HP-Senkung, Versenken, Beute einsammeln.
8. Erst bei bestandenem Test Android-Version/Export-Preset auf M303.7 anheben und APK mit derselben bisherigen Testpaket-ID/Signatur exportieren. Bestehendes Skript `tools/build_m3035_android.py` verwenden bzw. Versionsmetadaten ausdrücklich aktualisieren.
9. Web-Export mit identischer Kernszene testen, Touch-Ereignisse und Kamera.

## Beobachtete Risiken / weitere offene Arbeit
- Einfache Kugel-/Sphären-VFX sind bewusst nur eine erste visuelle Baseline, nicht die endgültigen Kanonenkugeln, Rauch-, Wasser- und Explosionseffekte.
- Projektilflug steuert das Ziel kontinuierlich an; exaktes ballistisches Verhalten, Sichtbehinderungen, Fehlschüsse und Schiff-zu-Schiff-Kollisionen fehlen noch.
- Der alte Kollisions-/Routenplaner arbeitet mit Inselkreisen; Küstensilhouetten und Kollision können abweichen.
- NPC-Kampf bleibt lokal simuliert, nicht serverautoritativ. M302-Backend wurde nicht angeschlossen.
- M303.6-APK und private SeaBattles-/SeaOfBones-Pakete wurden in dieser Runde nicht bearbeitet und nicht neu exportiert.
- Bei Screenshots weiterhin auf Schiffsskalen, Schiffsnamen, mobile HUD-Überlappungen und echtes Nahzoom achten.

## Referenzpriorität
SeaBattles (Seekarte/Bewegung), SeaOfBones (Schiffskunst/GUI), Battle of Sea (Schnellleiste/Bosse), Captain of Sea (PvP-Dichte), Seafight (Mechanik-FAQ), Korsan Timi, Sea of Pirates, Son Korsan, Legend Pirates (ergänzend).

## Nächster Entwicklungsschritt
Nach Parser-, Smoke- und Gameplay-Tests: M303.7 visuell verfeinern (Partikelschuss statt Kugelplatzhalter, Bugwelle, Zielringe, Schiffs-/Inselmaßstab, Kamera), APK und Web ausliefern. **Keine neuen großen MMO-Systeme vor der Spielkern-Abnahme.**
