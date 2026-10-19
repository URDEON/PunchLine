import os,subprocess,time,pathlib,sys,argparse
root=pathlib.Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--output',default='housing/docs/evidence/update_v0931/network')
args=parser.parse_args()
output=root/args.output
output.mkdir(parents=True,exist_ok=True)
cmd=['/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64','--headless','--path',str(root),'--script','qa/v0931/network_run.gd','--']
env=dict(os.environ,XDG_CONFIG_HOME='/workspace/.config',XDG_DATA_HOME='/workspace/.local/share',XDG_CACHE_HOME='/workspace/.cache')
processes=[]
try:
 for role in ['host','client']:
  log=(output/f'{role}.txt').open('w')
  processes.append((subprocess.Popen(cmd+[f'--housing-{role}'],env=env,stdout=log,stderr=subprocess.STDOUT),log))
  if role=='host':time.sleep(1)
 codes=[p.wait(timeout=300) for p,log in processes]
 for p,log in processes:log.flush()
 logs=[(output/f'{role}.txt').read_text() for role in ['host','client']]
 clean=all('ERROR:' not in content and 'FAIL ' not in content for content in logs)
 print('Spider ENet process exits:',codes)
 sys.exit(0 if codes==[0,0] and clean else 1)
finally:
 for p,log in processes:
  if p.poll() is None:p.terminate()
  log.close()
