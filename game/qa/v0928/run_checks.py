"""Current headless functional checks; keeps player preferences in an isolated temporary directory."""
import os, pathlib, subprocess, tempfile, sys
root=pathlib.Path(__file__).resolve().parents[2]
out=root/'housing/docs/evidence/update_v0928'
godot=os.environ.get('GODOT','/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64')
results=[]
with tempfile.TemporaryDirectory(prefix='punchline-0928-') as user_data:
 env=dict(os.environ,XDG_CONFIG_HOME='/workspace/.config',XDG_CACHE_HOME='/workspace/.cache',XDG_DATA_HOME=user_data)
 for suite in ['feature_test','systems_test','combat_test','multistorey_test','frontend_test','camera_jump_test','world_reset_test','thermal_surface_test']:
  path=f'qa/v0928/{suite}.gd' if suite!='camera_jump_test' else 'qa/rustcrawler/camera_jump_test.gd'
  with (out/(suite+'.log')).open('w') as log:
   p=subprocess.run([godot,'--headless','--fixed-fps','60','--path',str(root),'--script',path],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=150)
  content=(out/(suite+'.log')).read_text()
  passed=p.returncode==0 and 'RESULT ' in content and 'FAIL ' not in content and 'ERROR:' not in content
  results.append(passed);print(suite,passed,next((line for line in content.splitlines() if line.startswith('RESULT ')),'NO RESULT'),flush=True)
  if not passed:print(content,flush=True);break
sys.exit(0 if results and all(results) and len(results)==8 else 1)
