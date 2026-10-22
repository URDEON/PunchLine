"""Run the real Godot integration suite and reject logged script/runtime errors."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--render", action="store_true", help="Requires desktop/Xvfb and Vulkan")
    parser.add_argument("--suite", choices=("phase1", "shooter"), default="shooter")
    parser.add_argument("--soak-frames", type=int, default=7200)
    args = parser.parse_args()
    evidence = args.evidence.resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment["WARFARE_EVIDENCE_DIR"] = str(evidence)
    environment["WARFARE_SOAK_FRAMES"] = str(max(60, args.soak_frames))
    project = Path(__file__).resolve().parents[1]
    log = evidence / ("render.log" if args.render else ("shooter.log" if args.suite=="shooter" else "phase1.log"))
    command = [args.godot, "--path", str(project), "--log-file", str(log)]
    if args.render:
        command += ["--audio-driver", "Dummy", "--resolution", "1280x720",
                    "--script", "tests/render_shooter.gd" if args.suite=="shooter" else "tests/render_warfare.gd"]
    else:
        command += ["--headless", "--fixed-fps", "60",
                    "--script", "tests/warfare_shooter_test.gd" if args.suite=="shooter" else "tests/warfare_phase1_test.gd"]
    try:
        result = subprocess.run(command, env=environment, timeout=600, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"Godot run failed: {error}", file=sys.stderr)
        return 1
    content = log.read_text(errors="replace") if log.exists() else ""
    summary = re.search(r"RESULT (\d+)/(\d+) Warfare (?:phase 1|shooter) checks", content)
    marker = "RENDER_SHOOTER_DONE forward_plus" if args.suite=="shooter" else "RENDER_WARFARE_DONE forward_plus"
    completed = (marker in content if args.render
                 else summary is not None and summary[1] == summary[2])
    if result.returncode or re.search(r"(?:SCRIPT ERROR:|^ERROR:|^FAIL )", content, re.M) or not completed:
        print(f"Validation failed; inspect {log}", file=sys.stderr)
        return 1
    print(f"Verified Godot run. Evidence: {evidence}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
