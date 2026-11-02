# M302 — Production Convergence & Video QA

**Baseline:** `dfbfb8f` (M301)  
**Milestone:** M302 / `0.302.0`  
**Datum:** 2026-09-19  
**Engine:** Godot 4.7.2.stable (OpenGL Compatibility)

---

## 1. Baseline

- Repository: `Broosskyy/SOH-2`, Branch `main`
- Ausgangspunkt: Commit `dfbfb8f` — M301 mit funktionierenden Screenshots und `GameplayRuleset.rule_value()`
- `docs/qa_m301/` und `docs/qa_m301/flow/` wurden **nicht** verändert oder überschrieben
- Vor dem ersten Video-Lauf war ein Godot-`--import` auf einem frischen Clone nötig (Global-Class-Cache)

---

## 2. Untersuchte Source-Bereiche

| Bereich | Dateien / Pfade |
|---|---|
| QA Capture (M301) | `tools/capture_*.gd`, `docs/qa_m301/` |
| Video QA (M302) | `tools/qa_video_recorder.gd`, `tools/run_qa_video_flow.gd`, `tools/run_qa_video_batch.py` |
| Entry / Sea | `scripts/core/entry_flow.gd`, `scenes/entry.tscn`, `scenes/main.tscn` |
| Bootstrap | `scripts/core/game_bootstrap.gd` (~47 Catalog/Runtime-Instanzen) |
| World | `scripts/world/world_map_system.gd`, `encounter_director.gd` |
| Player / Input | `player_input.gd`, `ship_motor`, Module in `_add_ship_modules` |
| Camera | `scripts/gameplay/camera_rig.gd` (`IsometricCameraRig`) |
| Combat | `ship_weapons.gd`, `targeting_system.gd`, `enemy_ship_ai.gd` |
| HUD | `scripts/ui/game_hud.gd`, `nautical_hud.gd` |
| Content | `player_inventory.gd`, `combat_catalog.gd`, `data/m129_gameplay_rules_defaults.json` |

---

## 3. Video-QA-Architektur

Erweiterung der bestehenden Capture-Infrastruktur — **keine** parallele QA-Architektur.

```
Godot SceneTree (run_qa_video_flow.gd)
  → QAVideoRecorder (30 FPS PNG frames in user://qa_video_m302/<flow>/frames/)
  → run_qa_video_batch.py / validate_qa_videos.py
  → FFmpeg (VP9/WebM lokal; MP4/x264 schlägt hier fehl → WebM-Fallback)
  → docs/qa_m302/video_capture_report.json
```

**Ausführung:**

```powershell
# Einmalig nach frischem Clone:
Godot --headless --path . --import --quit

# Alle vier Flows:
py tools/run_qa_video_batch.py

# Nur Validierung bestehender Videos:
py tools/validate_qa_videos.py
```

**Regeln:** Keine Videos in Git (`docs/qa_m302/videos/` in `.gitignore`). FFmpeg wird zur Laufzeit erwartet, nicht committet.

---

## 4. Erzeugte Captures

| ID | Flow | Dauer | Auflösung | Größe | Ergebnis |
|---|---|---:|---|---:|---|
| `flow_a_entry_sea` | Entry → Guest → Sea | 13.5s | 804×581 | 343 KB | **PASS** |
| `flow_b_sea_gameplay` | Normaler Sea-Spawn | 13.5s | 804×581 | 390 KB | **PASS** |
| `flow_c_harbor_poi` | Hafen/POI (gezielte Position) | 15.0s | 804×581 | 456 KB | **PASS** |
| `flow_d_combat` | Combat mit 4 Gegnern | 17.0s | 804×581 | 495 KB | **PASS** |

Pfade (lokal, nicht in Git): `docs/qa_m302/videos/*.webm`  
Report: `docs/qa_m302/video_capture_report.json`  
Audit-Frames: `docs/qa_m302/frames/*_mid.png`

---

## 5. World-Befunde (aus echten Captures)

**Flow B (Normal Sea — unmanipuliert):**

- Meer, Schiff, HUD und Minimap rendern korrekt
- **Kein Hafen, keine Insel, kein sichtbares World-Dressing** im Kamerabild beim Standard-Spawn (0,0)
- Minimap zeigt Kontakte (grün/rot) — Welt-Systeme laufen, aber **Landmarks sind außerhalb des Sichtfelds**
- Quest „Erste Ausfahrt / Ablegen“ aktiv — Spawn-Komposition wirkt wie „offenes Meer“, nicht wie Hafenausfahrt

**Flow C (Harbor/POI — gezielte QA-Position):**

- Hafen, Pier, Gebäude, Safe-Zone-Banner und Küsten-Dressing **sichtbar und lesbar**
- Größenverhältnis Spieler ↔ Hafen plausibel
- World-Produktion funktioniert, wenn der Spieler in Hafennähe ist

**Bewertung:** P1 — Normal-Spawn liefert für neue Spieler wenig visuelle Orientierung; Content existiert, ist aber nicht im Default-Framing.

---

## 6. Camera-Befunde

- Isometrisches Top-Down mit `zoom_factor` ~1.0 beim Normal-Sea-Flow
- Schiff füllt ~8–12 % der Bildfläche — für Mobile lesbar, aber wenig Horizont/Tiefe
- Flow C mit `zoom_factor = 1.35` zeigt Hafen deutlich besser
- Combat-Framing (Flow D): Ziel oft „KEIN ZIEL“ trotz Gegnern in Reichweite — Kamera ok, Targeting-UX schwächer
- Capture-Auflösung 804×581 statt 1280×720 (Canvas-Stretch) — QA sollte künftig native Viewport-Größe loggen

**Bewertung:** P2 — Framing beim Standard-Sea ok für HUD-lastiges Mobile, schwach für World-Lesbarkeit.

---

## 7. Sailing-Befunde

- Tap-to-Sail via `set_navigation_world_target` funktioniert (Flow B: Vorwärtsfahrt sichtbar)
- Wake / Wasser-Reaktion vorhanden
- Drehung und Beschleunigung wirken funktional, nicht „schwer“ oder träge
- Linker Bereich: Steuerrad + AUTO GESPERRT — entspricht Richtung „links Kamera, nicht direkte Schiffssteuerung“
- Keine Regression bei Player-Modul-Init aus M301 beobachtet

**Bewertung:** P2 — Game Feel solide für Prototyp; Feintuning Geschwindigkeit/Wake später.

---

## 8. Combat-Befunde

- Flow D: 4 Gegner gespawnt, Target gesetzt, `auto_fire` aktiv
- Munition sinkt (140 → 131), Schild steigt (+7 SCHILD) — **Feedback-Loop lebt**
- Projektil-/Treffer-VFX in Capture teils subtil; HP-Balken am Gegner schwer erkennbar
- UI zeigt oft „KEIN ZIEL“ obwohl Combat läuft — HUD-Target-State nicht synchron
- Reload/Salve-Anzeige (100 %) stabil

**Bewertung:** P1 — Combat-System funktional, Target-Readability/HUD-Sync schwach.

---

## 9. HUD-Befunde

- Mobile-first Layout: Angriff unten rechts, Munition/Quickslots darum, Kamera links
- HP (Rumpf), Schild, EXP, Gold, Munition sichtbar
- Minimap rechts — gut, aber klein
- Viele Panels (Quest, Halloween, Admin, Status) — **mittlere Überladung**
- Touch-Targets groß genug (Haupt-Angriffskreis)
- Kein dauerhaftes Bottom-Menü im Sea-View — passt zur Richtung

**Bewertung:** P2 — Struktur stimmt, Informationsdichte und Target-UI brauchen Polish.

---

## 10. Harbor/Island/POI-Befunde

- Hafen-Assets, Safe-Zone, Banner und Pier in Flow C klar erkennbar
- POI-Lesbarkeit gut bei gezielter Annäherung
- Normal-Sea (Flow B) zeigt diese Inhalte **nicht** — reiner QA-/Produktbefund, kein Capture-Cheat

---

## 11. Source-Convergence-Befunde

`game_bootstrap.gd` enthält ~**47** Milestone-Catalog/Runtime-Instanzen (M160–M290, Readiness-Nodes).

| Klasse | Beispiele | Empfehlung |
|---|---|---|
| **A — Production Core** | `GameState`, `WorldMapSystem`, `ServiceLocator`, `CombatFeedback`, `EncounterDirector` | Behalten |
| **B — Production Foundation** | `LiveConfigRegistry`, `ContentSnapshotService`, `P1RegionalEnvironmentController` | Behalten, später dokumentieren |
| **C — Compatibility** | `VisualQA` (Web), `reconstruction_test_mode`, Guest-Meta | Behalten für QA/Web |
| **D — Milestone Historical** | `M252`–`M290` *Readiness* Nodes, viele `M1xx` Cataloge | Später in 1–2 Registry-Services konsolidieren |
| **E — Dead/Duplicate** | Keine sicher entfernbaren ohne Runtime-Beweis | **Nicht** entfernt in M302 |

**Konsolidierungsplan (post-M302):** Readiness-Nodes hinter einen `ProductionReadinessHub` falten; Cataloge nach Domäne (`CombatContent`, `MenuContent`, `AdminContent`) gruppieren — **kein Big-Bang**.

---

## 12. Inventory/Content-Befunde

- `PlayerInventory.START_STOCK`: 80+ Items hardcoded in GDScript
- `AMMO_IDS`, `OFFERS`: parallel zu `CombatCatalog` / JSON
- `GameplayRuleset` + `m129_gameplay_rules_defaults.json`: Balance für Progression/Inventory teilweise zentral
- `M162/M163/M165` Cataloge: dynamische Content-Definitionen — richtige Richtung
- **Widerspruch:** Harbor-Bundle-Targets in JSON (`iron: 240`) vs. `START_STOCK` (`iron: 140`)

**Source-of-Truth-Empfehlung:**

1. **Combat/Ammo:** `CombatCatalog` + `data/combat_*.json`
2. **Economy/Stock defaults:** `m129_gameplay_rules_defaults.json` → `GameplayRuleset`
3. **Offers/Shops:** `M161CommerceCatalog` / Live Config
4. **START_STOCK:** nur noch Bootstrap-Fallback, Werte aus JSON laden

---

## 13. Durchgeführte Safe Fixes

| Fix | Datei | Zweck |
|---|---|---|
| QA-Sync-Load für Entry→Sea Video | `entry_flow.gd` | Echter Flow ohne `load_threaded` Hang in SceneTree |
| Video-Recorder + 4 Flows | `tools/run_qa_video_flow.gd` | Automatisierte Video-QA |
| FFmpeg Batch + Validierung | `run_qa_video_batch.py`, `validate_qa_videos.py` | Encode + Report |
| Version 0.302.0 | `project.godot`, `README.md` | Konsistente Milestone-Version |
| Gitignore Videos/Frames | `.gitignore` | Keine großen Binaries in Git |

**Nicht geändert:** GameplayRuleset, Player-Init-Reihenfolge, M301-Screenshots, Kamera/Spawn für Flow B.

---

## 14. Verbleibende Probleme

| Prio | Problem |
|---|---|
| **P0** | — (keine Blocker für weiteres QA) |
| **P1** | Normal-Sea-Spawn ohne sichtbare Landmarks/Hafen |
| **P1** | HUD Target-Anzeige „KEIN ZIEL“ während aktivem Combat |
| **P1** | `selected_ship_id`/Roster-Warnungen bei direktem Sea-Load (Guest-Meta teilweise) |
| **P2** | Capture 804×581 statt 1280×720 |
| **P2** | MP4/x264-Encoding lokal fehlgeschlagen → WebM-Fallback |
| **P2** | HUD-Informationsdichte / Panel-Überlappung |
| **P3** | 47 Bootstrap-Readiness-Nodes — Wartungskosten |
| **P3** | Inventory-Daten auf mehrere Quellen verteilt |

---

## 15. Tests

| Test | Ergebnis |
|---|---|
| Godot `--import` | OK |
| M301 `capture_sea_direct.gd` | OK (SEA ready, PNG >170 KB) |
| Video QA 4/4 Flows | **PASS** (WebM, decodierbar, nicht schwarz) |
| `docs/qa_m301/` unverändert | OK |
| `m13_entry_test.gd` (headless) | Teilweise UI-Fehler (`get_visible_rect` null) — bekannt, kein M302-Blocker |

---

## 16. Einschränkungen

- Videos nur lokal; FFmpeg erforderlich
- Frischer Clone braucht Godot-Import vor `-s` Scripts
- Flow B bewusst ohne Spawn-Manipulation
- Visuelle Audit-Bewertung aus extrahierten Mid-Frames + Live-Capture, nicht manuelles Frame-by-Frame-Review aller 1800+ Frames

---

## 17. Empfehlung nächster Production-Milestone (M303)

1. **Spawn-Komposition:** Startposition/Kamera so, dass Erstausfahrt Hafen oder Landmark zeigt (ohne Fake-QA)
2. **Target HUD Sync:** `KEIN ZIEL` vs. `TargetingSystem.current_target` angleichen
3. **Video-QA in CI:** `run_qa_video_batch.py` als optionaler lokaler Gate
4. **Content-SoT Phase 1:** `START_STOCK` aus `m129` JSON lesen
5. **Readiness-Hub:** Inventar der 47 Bootstrap-Nodes → Deprecation-Liste

---

*M302 erfüllt das Ziel: bestehendes Spiel beobachten, messen, sichtbar machen — ohne Feature-Foundation-Sprawl.*
