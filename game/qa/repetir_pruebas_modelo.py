#!/usr/bin/env python3
"""Importa y repite las pruebas sin imagen con el ejecutable indicado por el usuario."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    engine, project, output = args.godot.resolve(), args.project.resolve(), args.output.resolve()
    if output.exists():
        parser.error('Usar una carpeta de resultados nueva para conservar registros anteriores')
    if not engine.is_file() or not (project/'project.godot').is_file():
        parser.error('Motor o proyecto no encontrado')
    output.mkdir(parents=True)
    version_env = os.environ.copy()
    version_cache = output/'version_cache'
    version_cache.mkdir()
    version_env['XDG_CACHE_HOME'] = str(version_cache)
    version = subprocess.check_output([str(engine),'--version'],env=version_env,text=True).strip()

    def run(name, arguments):
        env = os.environ.copy()
        for key, suffix in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
            directory = output/name/suffix
            directory.mkdir(parents=True)
            env[key] = str(directory)
        log = output/(name+'.log')
        command = [str(engine),'--headless','--path',str(project)]+arguments
        with log.open('w',encoding='utf-8') as stream:
            result = subprocess.run(command,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=180)
        contents = log.read_text(encoding='utf-8',errors='replace')
        results = re.findall(r'(?:RESULTADO|RESULT|DEMO RESULT)\s+(\d+)/(\d+)',contents)
        passed, total = map(int,results[-1]) if results else (0,0)
        status = result.returncode == 0 and 'SCRIPT ERROR' not in contents
        if name != 'importacion':
            status = status and total > 0 and passed == total and 'ERROR:' not in contents and not re.search(r'^FAIL ',contents,re.M)
        return {'name':name,'exit_code':result.returncode,'passed':passed,'total':total,'ok':status,
                'command':command,'log':log.name}

    report = {'version':version,'automated':True,'rendering':'headless','results':[]}
    imported = run('importacion',['--editor','--import'])
    report['results'].append(imported)
    if imported['ok']:
        suites = ['combat_test','polish_test','presentation_test','assets_test','revision_test','video_feedback_test','hud_test','hud_feedback_test','modelo_alien_test']
        with ThreadPoolExecutor(max_workers=3) as pool:
            jobs = [pool.submit(run,name,['--script','res://qa/'+name+'.gd','--fixed-fps','60']) for name in suites]
            for job in jobs:
                result = job.result()
                report['results'].append(result)
                print(result['name'],f"{result['passed']}/{result['total']}",result['ok'],flush=True)
        report['results'].append(run('demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--revision']))
        report['results'].append(run('hud_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--hud']))
        report['results'].append(run('modelo_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--modelo']))
    report['ok'] = all(result['ok'] for result in report['results'])
    (output/'resumen.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('RESUMEN',report['ok'],flush=True)
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
