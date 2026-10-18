"""Verifica recursos y controladores reales de un PCK, sin afirmar ejecución gráfica."""
import argparse,json,os,platform,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--godot',type=Path,required=True);p.add_argument('--pack',type=Path,required=True);p.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=False);results=[]
for name in ['stability_v0921_test','robot_grounding_v0921_test','replication_v0921_test','update_v0920_test','frontend_v0920_test','damage_network_v0920_test','embodiment_v0919_test','update_v0916_test']:
 env=dict(os.environ,XDG_CACHE_HOME=str(a.output/'cache'),XDG_DATA_HOME=str(a.output/name/'data'),XDG_CONFIG_HOME=str(a.output/name/'config'),NAOYA_QA_ARENA='legacy',NAOYA_NET_QA='1')
 command=[str(a.godot.resolve()),'--headless','--max-fps','60','--main-pack',str(a.pack.resolve()),'--script',str(a.project.resolve()/'qa'/(name+'.gd'))]
 try:r=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180);code=r.returncode;log=r.stdout
 except subprocess.TimeoutExpired:code=124;log='ERROR: TIMEOUT 180s'
 (a.output/(name+'.log')).write_text(log);match=re.search(r'RESULTADO (\d+)/(\d+)',log);passed,total=map(int,match.groups()) if match else (0,0)
 ok=code==0 and total>0 and passed==total and not re.search('SCRIPT ERROR|^ERROR:|^FAIL ',log,re.M)
 results.append(dict(name=name,passed=passed,total=total,ok=ok,command=command));print(name,passed,total,ok,flush=True)
report=dict(ok=all(x['ok'] for x in results),rendering='headless',native_windows=platform.system()=='Windows',results=results);(a.output/'resumen.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
