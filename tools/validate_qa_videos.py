#!/usr/bin/env python3
"""Validate existing M302 QA videos and refresh video_capture_report.json."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VIDEO_DIR = ROOT / "docs" / "qa_m302" / "videos"
REPORT_PATH = ROOT / "docs" / "qa_m302" / "video_capture_report.json"

FLOW_META = {
    "flow_a_entry_sea": {
        "flow": "Entry → Guest → Sea",
        "start_scene": "res://scenes/entry.tscn",
    },
    "flow_b_sea_gameplay": {
        "flow": "Normal Sea Gameplay",
        "start_scene": "res://scenes/main.tscn",
    },
    "flow_c_harbor_poi": {
        "flow": "Harbor / Island / POI",
        "start_scene": "res://scenes/main.tscn",
    },
    "flow_d_combat": {
        "flow": "Combat",
        "start_scene": "res://scenes/main.tscn",
    },
}


def ffprobe_path() -> str:
    import shutil

    path = shutil.which("ffprobe")
    if not path:
        raise FileNotFoundError("ffprobe not found on PATH")
    return path


def ffmpeg_path() -> str:
    import shutil

    path = shutil.which("ffmpeg")
    if not path:
        raise FileNotFoundError("ffmpeg not found on PATH")
    return path


def probe_video(ffprobe: str, video_path: Path) -> dict:
    cmd = [
        ffprobe,
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=width,height,codec_name",
        "-show_entries",
        "format=duration,size",
        "-of",
        "json",
        str(video_path),
    ]
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode != 0:
        return {"exists": True, "decodable": False, "error": (result.stdout or "")[-500:]}
    data = json.loads(result.stdout or "{}")
    stream = (data.get("streams") or [{}])[0]
    fmt = data.get("format") or {}
    duration = float(fmt.get("duration", 0) or 0)
    return {
        "exists": True,
        "decodable": duration > 0,
        "width": int(stream.get("width", 0) or 0),
        "height": int(stream.get("height", 0) or 0),
        "codec": str(stream.get("codec_name", "")),
        "duration_sec": duration,
        "file_size": int(fmt.get("size", video_path.stat().st_size)),
    }


def black_frame_check(ffmpeg: str, video_path: Path) -> dict:
    cmd = [
        ffmpeg,
        "-i",
        str(video_path),
        "-vf",
        "blackdetect=d=0.5:pix_th=0.12",
        "-an",
        "-f",
        "null",
        "-",
    ]
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    text = (result.stdout or "") + (result.stderr or "")
    hits = re.findall(r"black_start:([0-9.]+) black_end:([0-9.]+)", text)
    return {"mostly_black": len(hits) > 0, "black_segments": len(hits)}


def main() -> int:
    ffprobe = ffprobe_path()
    ffmpeg = ffmpeg_path()
    captured_at = datetime.now(timezone.utc).isoformat()
    prior = {}
    if REPORT_PATH.exists():
        prior = json.loads(REPORT_PATH.read_text(encoding="utf-8"))
    prior_steps = {
        item.get("capture_id"): item.get("steps", [])
        for item in prior.get("captures", [])
        if isinstance(item, dict)
    }
    prior_warnings = {
        item.get("capture_id"): item.get("warnings", [])
        for item in prior.get("captures", [])
        if isinstance(item, dict)
    }
    report = {
        "milestone": "M302",
        "baseline_commit": "dfbfb8f",
        "captured_at": captured_at,
        "engine": prior.get("engine", ""),
        "captures": [],
    }
    failures = 0
    for flow_id, meta in FLOW_META.items():
        video_path = VIDEO_DIR / f"{flow_id}.webm"
        if not video_path.exists():
            video_path = VIDEO_DIR / f"{flow_id}.mp4"
        record = {
            "capture_id": flow_id,
            "milestone": "M302",
            "captured_at": captured_at,
            "start_scene": meta["start_scene"],
            "flow": meta["flow"],
            "output_path": "",
            "format": "",
            "resolution": "",
            "fps": 30,
            "duration_sec": 0.0,
            "steps": prior_steps.get(flow_id, []),
            "result": "FAIL",
            "warnings": list(prior_warnings.get(flow_id, [])),
            "error": "",
            "file_size": 0,
            "decodable": False,
            "mostly_black": False,
        }
        if not video_path.exists() or video_path.stat().st_size <= 0:
            record["error"] = "missing_video"
            failures += 1
        else:
            record["output_path"] = str(video_path.relative_to(ROOT)).replace("\\", "/")
            record["format"] = video_path.suffix.lstrip(".")
            probe = probe_video(ffprobe, video_path)
            record["decodable"] = bool(probe.get("decodable"))
            record["duration_sec"] = float(probe.get("duration_sec", 0.0))
            record["file_size"] = int(probe.get("file_size", 0))
            if probe.get("width") and probe.get("height"):
                record["resolution"] = f"{probe['width']}x{probe['height']}"
            black = black_frame_check(ffmpeg, video_path)
            record["mostly_black"] = bool(black.get("mostly_black"))
            if not record["decodable"] or record["duration_sec"] < 2.0:
                record["error"] = "invalid_duration"
                failures += 1
            elif record["mostly_black"]:
                record["result"] = "WARN"
            else:
                record["result"] = "PASS"
        report["captures"].append(record)
    report["summary"] = {
        "total": len(FLOW_META),
        "pass": sum(1 for c in report["captures"] if c["result"] == "PASS"),
        "warn": sum(1 for c in report["captures"] if c["result"] == "WARN"),
        "fail": sum(1 for c in report["captures"] if c["result"] == "FAIL"),
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["summary"], indent=2))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
