#!/usr/bin/env python3
"""M302 video QA: Godot frame capture -> FFmpeg encode -> validation report."""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs" / "qa_m302"
VIDEO_DIR = DOCS / "videos"
REPORT_PATH = DOCS / "video_capture_report.json"

FLOWS = [
    {
        "id": "flow_a_entry_sea",
        "label": "Entry → Guest → Sea",
        "start_scene": "res://scenes/entry.tscn",
        "duration_target_sec": 15,
    },
    {
        "id": "flow_b_sea_gameplay",
        "label": "Normal Sea Gameplay",
        "start_scene": "res://scenes/main.tscn",
        "duration_target_sec": 14,
    },
    {
        "id": "flow_c_harbor_poi",
        "label": "Harbor / Island / POI",
        "start_scene": "res://scenes/main.tscn",
        "duration_target_sec": 15,
    },
    {
        "id": "flow_d_combat",
        "label": "Combat",
        "start_scene": "res://scenes/main.tscn",
        "duration_target_sec": 17,
    },
]


def find_godot() -> Path:
    env = os.environ.get("GODOT_BIN")
    if env:
        path = Path(env)
        if path.exists():
            return path
    local = ROOT / "tools" / "godot-4.7.2" / "Godot_v4.7.2-stable_win64.exe"
    if local.exists():
        return local
    local_console = ROOT / "tools" / "godot-4.7.2" / "Godot_v4.7.2-stable_win64_console.exe"
    if local_console.exists():
        return local_console
    raise FileNotFoundError(
        "Godot binary not found. Set GODOT_BIN or install to tools/godot-4.7.2/"
    )


def find_ffmpeg(name: str) -> str:
    path = shutil.which(name)
    if path:
        return path
    raise FileNotFoundError(
        f"{name} not found on PATH. Install FFmpeg (e.g. winget install Gyan.FFmpeg) and retry."
    )


def godot_userdata() -> Path:
    if sys.platform == "win32":
        appdata = os.environ.get("APPDATA", "")
        return Path(appdata) / "Godot" / "app_userdata" / "Abyssal Dominion"
    return Path.home() / ".local" / "share" / "godot" / "app_userdata" / "Abyssal Dominion"


def run_flow(godot: Path, flow_id: str, fps: int = 30) -> tuple[int, str, dict]:
    env = os.environ.copy()
    env["QA_VIDEO_FLOW"] = flow_id
    env["QA_VIDEO_FPS"] = str(fps)
    cmd = [
        str(godot),
        "--path",
        str(ROOT),
        "--resolution",
        "1280x720",
        "-s",
        "res://tools/run_qa_video_flow.gd",
    ]
    result = subprocess.run(
        cmd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=300,
        env=env,
    )
    log = result.stdout
    meta = {}
    match = re.search(
        r"QA_VIDEO_DONE flow_id=(\S+) frames=(\d+) fps=(\d+) resolution=(\d+)x(\d+) steps=([^\s]+) warnings=(.*)",
        log,
    )
    if match:
        meta = {
            "flow_id": match.group(1),
            "frames": int(match.group(2)),
            "fps": int(match.group(3)),
            "width": int(match.group(4)),
            "height": int(match.group(5)),
            "steps": match.group(6).split(",") if match.group(6) else [],
            "warnings": [w for w in match.group(7).split("|") if w],
        }
    return result.returncode, log, meta


def encode_video(ffmpeg: str, frames_dir: Path, output_path: Path, fps: int) -> tuple[Path | None, str]:
    pattern = frames_dir / "frame_%06d.png"
    if not any(frames_dir.glob("frame_*.png")):
        return None, "no_frames"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    mp4 = output_path if output_path.suffix.lower() == ".mp4" else output_path.with_suffix(".mp4")
    webm = output_path.with_suffix(".webm")
    for candidate, args in (
        (mp4, ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart"]),
        (webm, ["-c:v", "libvpx-vp9", "-pix_fmt", "yuv420p"]),
    ):
        cmd = [ffmpeg, "-y", "-framerate", str(fps), "-i", str(pattern), *args, str(candidate)]
        result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if result.returncode == 0 and candidate.exists() and candidate.stat().st_size > 1024:
            if candidate != mp4 and mp4.exists() and mp4.stat().st_size <= 0:
                mp4.unlink(missing_ok=True)
            return candidate, ""
    return None, (result.stdout or "")[-2000:]


def probe_video(ffprobe: str, video_path: Path) -> dict:
    if not video_path.exists():
        return {"exists": False}
    cmd = [
        ffprobe,
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=width,height,avg_frame_rate,duration,codec_name",
        "-show_entries",
        "format=duration,size",
        "-of",
        "json",
        str(video_path),
    ]
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode != 0:
        return {"exists": True, "decodable": False, "error": result.stdout[-500:]}
    data = json.loads(result.stdout or "{}")
    streams = data.get("streams", [])
    stream = streams[0] if streams else {}
    fmt = data.get("format", {})
    duration = float(fmt.get("duration", stream.get("duration", 0)) or 0)
    return {
        "exists": True,
        "decodable": True,
        "width": int(stream.get("width", 0) or 0),
        "height": int(stream.get("height", 0) or 0),
        "codec": stream.get("codec_name", ""),
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
    black_hits = re.findall(r"black_start:([0-9.]+) black_end:([0-9.]+)", text)
    mostly_black = len(black_hits) > 0
    return {"mostly_black": mostly_black, "black_segments": len(black_hits)}


def cleanup_frames(frames_dir: Path) -> None:
    if not frames_dir.exists():
        return
    for frame in frames_dir.glob("frame_*.png"):
        frame.unlink(missing_ok=True)


def main() -> int:
    DOCS.mkdir(parents=True, exist_ok=True)
    VIDEO_DIR.mkdir(parents=True, exist_ok=True)
    godot = find_godot()
    ffmpeg = find_ffmpeg("ffmpeg")
    ffprobe = find_ffmpeg("ffprobe")
    userdata = godot_userdata()
    captured_at = datetime.now(timezone.utc).isoformat()
    report = {
        "milestone": "M302",
        "baseline_commit": "dfbfb8f",
        "captured_at": captured_at,
        "engine": subprocess.check_output([str(godot), "--version"], text=True).strip(),
        "captures": [],
    }
    failures = 0
    for flow in FLOWS:
        flow_id = flow["id"]
        record = {
            "capture_id": flow_id,
            "milestone": "M302",
            "captured_at": captured_at,
            "start_scene": flow["start_scene"],
            "flow": flow["label"],
            "output_path": "",
            "format": "",
            "resolution": "",
            "fps": 30,
            "duration_sec": 0.0,
            "steps": [],
            "result": "FAIL",
            "warnings": [],
            "error": "",
            "file_size": 0,
            "decodable": False,
            "mostly_black": False,
        }
        try:
            code, log, meta = run_flow(godot, flow_id)
            record["steps"] = meta.get("steps", [])
            record["warnings"] = meta.get("warnings", [])
            if code != 0:
                record["error"] = f"godot_exit_{code}"
                failures += 1
                report["captures"].append(record)
                continue
            frames_rel = Path("qa_video_m302") / flow_id / "frames"
            frames_dir = userdata / frames_rel
            fps = int(meta.get("fps", 30))
            record["fps"] = fps
            width = int(meta.get("width", 0))
            height = int(meta.get("height", 0))
            if width and height:
                record["resolution"] = f"{width}x{height}"
            mp4 = VIDEO_DIR / f"{flow_id}.mp4"
            video_path, err = encode_video(ffmpeg, frames_dir, mp4, fps)
            if video_path is None or not video_path.exists():
                record["error"] = err or "encode_failed"
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
                if record["file_size"] <= 0 or record["duration_sec"] < 2.0:
                    record["error"] = "invalid_duration_or_size"
                    record["result"] = "FAIL"
                    failures += 1
                elif not record["decodable"]:
                    record["error"] = "not_decodable"
                    record["result"] = "FAIL"
                    failures += 1
                elif record["mostly_black"]:
                    record["warnings"].append("mostly_black_detected")
                    record["result"] = "WARN"
                else:
                    record["result"] = "PASS"
                cleanup_frames(frames_dir)
        except Exception as exc:  # noqa: BLE001 - QA orchestrator must continue
            record["error"] = str(exc)
            failures += 1
        report["captures"].append(record)
    report["summary"] = {
        "total": len(FLOWS),
        "pass": sum(1 for c in report["captures"] if c["result"] == "PASS"),
        "warn": sum(1 for c in report["captures"] if c["result"] == "WARN"),
        "fail": sum(1 for c in report["captures"] if c["result"] == "FAIL"),
    }
    REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["summary"], indent=2))
    print(f"Report: {REPORT_PATH}")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
