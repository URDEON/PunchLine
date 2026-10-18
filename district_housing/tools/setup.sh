#!/usr/bin/env bash
set -euo pipefail
cd /workspace/PunchLine
python3 -m venv /workspace/punchline-tools
/workspace/punchline-tools/bin/python -m pip install --disable-pip-version-check -r district_housing/tools/requirements.txt
mkdir -p /workspace/godot441 /workspace/.cache /workspace/.config /workspace/.local/share
if [ ! -x /workspace/godot441/Godot_v4.4.1-stable_linux.x86_64 ]; then
  curl -fL --retry 2 -o /tmp/godot441.zip https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip
  curl -fL --retry 2 -o /tmp/godot441.SHA512-SUMS.txt https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/SHA512-SUMS.txt
  python3 - <<'PY'
import hashlib, pathlib, zipfile
archive = pathlib.Path('/tmp/godot441.zip')
line = next(s for s in pathlib.Path('/tmp/godot441.SHA512-SUMS.txt').read_text().splitlines() if s.endswith('Godot_v4.4.1-stable_linux.x86_64.zip'))
assert hashlib.sha512(archive.read_bytes()).hexdigest() == line.split()[0], 'Godot checksum mismatch'
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall('/workspace/godot441')
pathlib.Path('/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64').chmod(0o755)
PY
fi
export XDG_DATA_HOME=/workspace/.local/share
export XDG_CACHE_HOME=/workspace/.cache
export XDG_CONFIG_HOME=/workspace/.config
/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64 --version
