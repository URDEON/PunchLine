#!/usr/bin/env python3
"""Abre tres aplicaciones exportadas por su entrada normal y comprueba admisión/cierre."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--port',type=int,default=17904)
    args=parser.parse_args(); root=args.output.resolve();root.mkdir(parents=True,exist_ok=False);jobs=[]
    try:
        for role in ['host','client1','client2']:
            env=os.environ.copy()
            for key,suffix in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
                path=root/role/suffix;path.mkdir(parents=True);env[key]=str(path)
            log=(root/(role+'.log')).open('w')
            parameters=['--host'] if role=='host' else ['--join=127.0.0.1']
            if role=='client1': parameters.append('--robot')
            command=[str(args.binary.resolve()),'--headless','--max-fps','60','--quit-after','450','--','--online','--network-log',f'--port={args.port}',f'--nickname={role}']+parameters
            p=subprocess.Popen(command,cwd=args.binary.resolve().parent,env=env,stdout=log,stderr=subprocess.STDOUT)
            jobs.append((role,p,log,command));time.sleep(.5)
        results=[]
        for role,p,log,command in jobs:
            try:p.wait(timeout=25)
            except subprocess.TimeoutExpired:p.terminate();p.wait(timeout=10)
            log.close();contents=(root/(role+'.log')).read_text(errors='replace')
            ok=p.returncode==0 and 'NET PLAYERS 3 ACTIVE true' in contents and 'ERROR:' not in contents and 'SCRIPT ERROR' not in contents
            results.append({'role':role,'ok':ok,'exit_code':p.returncode,'command':command})
        report={'real_exported_app':True,'ok':all(x['ok'] for x in results),'results':results}
        (root/'summary.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
        return 0 if report['ok'] else 1
    finally:
        for _,p,log,_ in jobs:
            if p.poll() is None:p.terminate();p.wait(timeout=10)
            if not log.closed:log.close()
if __name__=='__main__': raise SystemExit(main())
