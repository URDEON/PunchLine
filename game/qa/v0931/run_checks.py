"""Current release regression runner; writes fresh evidence and isolates user data."""
import os
import argparse
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[2]
output = root / 'housing/docs/evidence/update_v0931'
output.mkdir(parents=True, exist_ok=True)
godot = os.environ.get('GODOT', '/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64')
suites = ['v0931/world_features_test', 'v0931/window_climb_test',
          'v0930/surface_motion_test', 'v0930/camera_jump_test',
          'v0930/feature_test', 'v0931/multistorey_test',
          'v0931/destruction_test', 'v0931/frontend_test',
          'v0929/camera_audio_test', 'v0929/critical_test',
          'v0929/human_access_test', 'v0929/thermal_surface_test']
parser = argparse.ArgumentParser()
parser.add_argument('--from-test', choices=[Path(s).name for s in suites])
args = parser.parse_args()
if args.from_test:
    suites = suites[next(i for i,s in enumerate(suites) if Path(s).name == args.from_test):]
with tempfile.TemporaryDirectory(prefix='punchline-0931-') as temporary:
    for suite in suites:
        name = Path(suite).name
        env = dict(os.environ, XDG_CONFIG_HOME='/workspace/.config',
                   XDG_CACHE_HOME='/workspace/.cache', XDG_DATA_HOME=str(Path(temporary)/name))
        path = output / (name + '.log')
        with path.open('w') as log:
            result = subprocess.run([godot, '--headless', '--fixed-fps', '60',
                '--path', str(root), '--script', f'qa/{suite}.gd'],
                env=env, stdout=log, stderr=subprocess.STDOUT, timeout=300)
        content = path.read_text()
        summary = next((line for line in content.splitlines() if line.startswith('RESULT ')), 'NO RESULT')
        passed = result.returncode == 0 and summary != 'NO RESULT' and 'FAIL ' not in content and 'ERROR:' not in content
        print(name, passed, summary, flush=True)
        if not passed:
            print(content)
            sys.exit(1)
