#!/usr/bin/env python3
"""Extract FSB5 AudioClips and convert them to WAV with ffmpeg."""

from __future__ import annotations

import argparse
import re
import subprocess
import struct
import wave
from pathlib import Path

import UnityPy
from UnityPy.helpers.ResourceReader import get_resource_data

from inventory_unity_build import asset_files


def clean(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", value).strip("._") or "audio"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    converted = 0
    for source in asset_files(args.root):
        env = UnityPy.load(str(source))
        for obj in env.objects:
            if obj.type.name != "AudioClip":
                continue
            audio = obj.read()
            if audio.m_AudioData:
                payload = bytes(audio.m_AudioData)
            else:
                resource = audio.m_Resource
                payload = get_resource_data(resource.m_Source, obj.assets_file, resource.m_Offset, resource.m_Size)
            stem = f"{clean(audio.m_Name)}__{obj.path_id}"
            source_path = args.output / f"{stem}.fsb"
            output_path = args.output / f"{stem}.wav"
            source_path.write_bytes(payload)
            if payload[:4] == b"FSB5" and struct.unpack_from("<I", payload, 24)[0] == 2:
                # Unity PCM16 clips are stored in a one-sample FSB5 container.
                sample_headers = struct.unpack_from("<I", payload, 12)[0]
                name_table = struct.unpack_from("<I", payload, 16)[0]
                data_size = struct.unpack_from("<I", payload, 20)[0]
                start = 60 + sample_headers + name_table
                pcm = payload[start : start + data_size]
                with wave.open(str(output_path), "wb") as handle:
                    handle.setnchannels(int(audio.m_Channels or 2))
                    handle.setsampwidth(2)
                    handle.setframerate(int(audio.m_Frequency or 44100))
                    handle.writeframes(pcm)
                converted += 1
            else:
                result = subprocess.run(
                    ["ffmpeg", "-nostdin", "-y", "-loglevel", "error", "-i", str(source_path), str(output_path)],
                    check=False,
                )
                if result.returncode == 0:
                    converted += 1
    print(f"converted={converted}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
