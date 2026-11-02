# M302 Video QA

Lokale Video-Captures für Production Convergence. Videos werden **nicht** in Git committet.

## Voraussetzungen

- Godot 4.7.2 (`tools/godot-4.7.2/` oder `GODOT_BIN`)
- FFmpeg auf `PATH` (`winget install Gyan.FFmpeg`)

## Ausführung

```powershell
# Nach frischem Clone einmalig:
.\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import --quit

# Alle Flows erfassen + Report:
py tools/run_qa_video_batch.py

# Nur vorhandene Videos validieren:
py tools/validate_qa_videos.py
```

## Flows

| Env `QA_VIDEO_FLOW` | Beschreibung |
|---|---|
| `flow_a_entry_sea` | Splash → Login → Guest → Home → Play → Sea |
| `flow_b_sea_gameplay` | Normaler Sea-Spawn, Segeln, kein Positions-Cheat |
| `flow_c_harbor_poi` | Gezielte Hafen-/POI-Position |
| `flow_d_combat` | Gegner, Targeting, Auto-Fire |

Output: `docs/qa_m302/videos/*.webm`  
Report: `docs/qa_m302/video_capture_report.json`
