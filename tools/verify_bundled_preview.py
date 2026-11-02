#!/usr/bin/env python3
"""Check the real bundled Web build over loopback; never publish or install tools."""
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from preview import validate_engine

ROOT = Path(__file__).resolve().parents[1]


def main():
    report = {"passed": False, "visual_verification": False}
    process = subprocess.Popen([sys.executable, str(ROOT / "tools/preview.py"), "--port", "18077"],
                               cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    try:
        base = "http://127.0.0.1:18077"
        for _ in range(100):
            if process.poll() is not None:
                raise RuntimeError("Preview process stopped before verification")
            try:
                with urllib.request.urlopen(base + "/__preview__/status", timeout=0.3) as response:
                    stamp = json.load(response)
                break
            except (urllib.error.URLError, TimeoutError):
                time.sleep(0.1)
        else:
            raise RuntimeError("Preview readiness timeout")
        with urllib.request.urlopen(base, timeout=3) as response:
            shell = response.read().decode()
        with urllib.request.urlopen(urllib.request.Request(base + "/index.wasm", method="HEAD"), timeout=3) as response:
            wasm_type = response.headers.get("Content-Type")
        assert stamp["milestone"] == "M18"
        validate_engine(stamp["engine"])
        assert "M18 Preview" in shell
        assert wasm_type == "application/wasm"
        report.update(passed=True, engine=stamp["engine"], milestone=stamp["milestone"], source_sha256=stamp["source_sha256"],
                      html_current=True, wasm_mime=wasm_type)
    except Exception as exc:
        report["error"] = str(exc)
    finally:
        process.terminate()
        try:
            log, _ = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            log, _ = process.communicate()
        (ROOT / "docs/m18_http_preview.log").write_text(log)
        (ROOT / "docs/m18_http_validation.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
