import os,subprocess,time,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[2]
output=root/'housing/docs/evidence/network'
output.mkdir(parents=True,exist_ok=True)
cmd=['/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64','--headless','--path',str(root),'--script','housing/qa/network_run.gd','--']
env=dict(os.environ,XDG_CONFIG_HOME='/workspace/.config',XDG_DATA_HOME='/workspace/.local/share',XDG_CACHE_HOME='/workspace/.cache')
processes=[]
try:
 for role in ['host','client']:
  log=(output/f'{role}.txt').open('w')
  processes.append((subprocess.Popen(cmd+[f'--housing-{role}'],env=env,stdout=log,stderr=subprocess.STDOUT),log))
  if role=='host':time.sleep(1)
 codes=[p.wait(timeout=115) for p,log in processes]
 print('ENet process exits:',codes)
 sys.exit(0 if codes==[0,0] else 1)
finally:
 for p,log in processes:
  if p.poll() is None:p.terminate()
  log.close()
