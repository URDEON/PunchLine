"""Functional release checks. Preferences and saved worlds are isolated per suite."""
import os
from pathlib import Path
import subprocess
import tempfile
import sys
root=Path(__file__).resolve().parents[2]
output=root/'housing/docs/evidence/update_v0929'
output.mkdir(parents=True,exist_ok=True)
godot=os.environ.get('GODOT','/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64')
suites=['feature_test','camera_jump_test','camera_audio_test','critical_test','destruction_test','scenery_test','human_access_test','combat_test','multistorey_test','frontend_test','world_reset_test','thermal_surface_test']
results=[]
with tempfile.TemporaryDirectory(prefix='punchline-0929-') as temporary:
 for suite in suites:
  env=dict(os.environ,XDG_CONFIG_HOME='/workspace/.config',XDG_CACHE_HOME='/workspace/.cache',XDG_DATA_HOME=str(Path(temporary)/suite))
  path=output/(suite+'.log')
  with path.open('w') as log:
   result=subprocess.run([godot,'--headless','--fixed-fps','60','--path',str(root),'--script',f'qa/v0929/{suite}.gd'],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
  content=path.read_text()
  summary=next((line for line in content.splitlines() if line.startswith('RESULT ')),'NO RESULT')
  passed=result.returncode==0 and summary!='NO RESULT' and 'FAIL ' not in content and 'ERROR:' not in content
  results.append(passed);print(suite,passed,summary,flush=True)
  if not passed:print(content,flush=True);break
sys.exit(0 if len(results)==len(suites) and all(results) else 1)
