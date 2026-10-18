"""Pruebas 0.9.19: controladores reales locales; no simula una conexión WAN."""
import argparse,json,os,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--godot',type=Path,required=True);p.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent);p.add_argument('--output',type=Path,required=True)
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=False)
results=[]
for suite in ['menu_revision_test','network/ui_test','network/full_local','robot_hud_v0914_test','update_v0916_test','network_v0916_test','terrain_v0916_test','navigation_v0916_test','update_v0917_test','network_v0917_test','locomotion_v0918_test','locomotion_network_v0918_test','joint_caps_v0918_test','embodiment_v0919_test','embodiment_network_v0919_test']:
 name=suite.replace('/','_');env=dict(os.environ,NAOYA_QA_ARENA='legacy',NAOYA_NET_QA='1',XDG_CACHE_HOME=str(a.output/'cache'),XDG_DATA_HOME=str(a.output/name/'data'),XDG_CONFIG_HOME=str(a.output/name/'config'))
 command=[str(a.godot.resolve()),'--headless','--max-fps','120','--path',str(a.project.resolve()),'--script','res://qa/'+suite+'.gd']
 try:r=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180);code=r.returncode;log=r.stdout
 except subprocess.TimeoutExpired:code=124;log='ERROR: TIMEOUT 180s'
 (a.output/(name+'.log')).write_text(log)
 m=re.search(r'RESULTADO (\d+)/(\d+)',log);passed,total=map(int,m.groups()) if m else (0,0)
 ok=code==0 and total>0 and passed==total and not re.search(r'(SCRIPT ERROR|^ERROR:|^FAIL )',log,re.M)
 results.append(dict(suite=suite,passed=passed,total=total,ok=ok,command=command));print(name,passed,total,ok,flush=True)
report=dict(automated=True,rendering='headless',transport='local_controller_harness',ok=all(r['ok'] for r in results),results=results)
(a.output/'resumen.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
