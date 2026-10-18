#!/usr/bin/env python3
"""Prueba ENet real: anfitrión y dos clientes en procesos separados, sin video."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[2])
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--scenario',choices=['combat','mechas'],default='combat')
    parser.add_argument('--port',type=int,default=17877)
    parser.add_argument('--graphics-role',choices=['host','client1','client2'])
    args = parser.parse_args()
    root = args.output.resolve()
    root.mkdir(parents=True,exist_ok=False)
    jobs = []
    try:
        for role in ['host','client1','client2']:
            env = os.environ.copy()
            for key,suffix in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
                path = root/role/suffix; path.mkdir(parents=True); env[key] = str(path)
            env.update(NAOYA_NET_SCENARIO=args.scenario,NAOYA_NET_QA='1',NAOYA_NET_ROLE=role,NAOYA_NET_OUTPUT=str(root),NAOYA_NET_PORT=str(args.port))
            log = (root/(role+'.log')).open('w')
            command = [str(args.godot.resolve()),'--headless','--max-fps','60','--path',str(args.project.resolve()),'--script','res://qa/network/run.gd']
            if role == args.graphics_role:
                command.remove('--headless')
                command += ['--rendering-driver','opengl3','--audio-driver','Dummy']
                env['NAOYA_NET_CAPTURE']='1'
                env['MESA_SHADER_CACHE_DIR']=str(Path(args.project).resolve().parent/'.cache'/'mesa_shader_cache')
            process = subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT)
            jobs.append((role,process,log,command))
            time.sleep(.7)
        deadline = time.monotonic()+(230 if args.graphics_role else 110)
        while any(process.poll() is None for _,process,_,_ in jobs) and time.monotonic() < deadline:
            time.sleep(.2)
        results = []
        for role,process,log,command in jobs:
            if process.poll() is None: process.terminate(); process.wait(timeout=10)
            log.close()
            contents = (root/(role+'.log')).read_text(errors='replace')
            results.append({'role':role,'exit_code':process.returncode,'ok':process.returncode == 0 and 'SCRIPT ERROR' not in contents and 'ERROR:' not in contents and 'FAIL ' not in contents,'command':command})
        report = {'rendering':args.graphics_role+' graphical, other roles headless' if args.graphics_role else 'headless','real_enet':True,'players':3,'results':results,'ok':all(item['ok'] for item in results)}
        (root/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps(report,indent=2))
        return 0 if report['ok'] else 1
    finally:
        for _,process,log,_ in jobs:
            if process.poll() is None: process.terminate(); process.wait(timeout=10)
            if not log.closed: log.close()

if __name__ == '__main__': raise SystemExit(main())
