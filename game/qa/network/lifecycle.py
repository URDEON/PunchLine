#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

def main():
    parser=argparse.ArgumentParser(description='Prueba real de capacidad, protocolo, cierre y timeout ENet.')
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[2])
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--port',type=int,default=17890)
    args=parser.parse_args(); root=args.output.resolve(); root.mkdir(parents=True,exist_ok=False); jobs=[]
    def launch(role):
        env=os.environ.copy()
        for key,suffix in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
            p=root/role/suffix; p.mkdir(parents=True); env[key]=str(p)
        env.update(NAOYA_NET_ROLE=role,NAOYA_NET_QA='1',NAOYA_NET_OUTPUT=str(root),NAOYA_NET_PORT=str(args.port))
        log=(root/(role+'.log')).open('w')
        command=[str(args.godot.resolve()),'--headless','--max-fps','60','--path',str(args.project.resolve()),'--script','res://qa/network/run.gd']
        p=subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT); jobs.append((role,p,log,command))
    def wait_file(name):
        until=time.monotonic()+30
        while not (root/name).exists() and time.monotonic()<until: time.sleep(.1)
        if not (root/name).exists(): raise RuntimeError('No llegó la fase '+name)
    try:
        for role in ['lifecycle_host','lifecycle_one','lifecycle_two']: launch(role); time.sleep(.6)
        wait_file('three'); launch('lifecycle_extra'); launch('lifecycle_timeout')
        wait_file('bad_start'); launch('lifecycle_bad')
        for _,p,_,_ in jobs: p.wait(timeout=50)
        records=[]
        for role,p,log,command in jobs:
            log.close(); content=(root/(role+'.log')).read_text(errors='replace')
            result=json.loads((root/(role+'.json')).read_text())
            result.update(role=role,exit_code=p.returncode,command=command)
            result['ok']=result['ok'] and p.returncode==0 and 'ERROR:' not in content and 'SCRIPT ERROR' not in content
            records.append(result)
        report={'real_enet':True,'ok':all(r['ok'] for r in records),'results':records}
        (root/'summary.json').write_text(json.dumps(report,indent=2)+'\n'); print(json.dumps(report,indent=2))
        return 0 if report['ok'] else 1
    finally:
        for _,p,log,_ in jobs:
            if p.poll() is None: p.terminate(); p.wait(timeout=10)
            if not log.closed: log.close()
if __name__=='__main__': raise SystemExit(main())
