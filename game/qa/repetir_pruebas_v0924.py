#!/usr/bin/env python3
"""Importa y repite las pruebas sin imagen con el ejecutable indicado por el usuario."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import subprocess


def main(default_release='0.9.24'):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--release', default=default_release, choices=['0.9.7','0.9.8','0.9.9','0.9.10','0.9.11','0.9.12','0.9.13','0.9.14','0.9.15','0.9.16','0.9.17','0.9.18','0.9.19','0.9.20','0.9.21','0.9.24'])
    args = parser.parse_args()
    engine, project, output = args.godot.resolve(), args.project.resolve(), args.output.resolve()
    if output.exists():
        parser.error('Usar una carpeta de resultados nueva para conservar registros anteriores')
    if not engine.is_file() or not (project/'project.godot').is_file():
        parser.error('Motor o proyecto no encontrado')
    output.mkdir(parents=True)
    version_env = os.environ.copy()
    for key,suffix in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
        directory = output/'version'/suffix
        directory.mkdir(parents=True)
        version_env[key] = str(directory)
    version = subprocess.check_output([str(engine),'--version'],env=version_env,text=True).strip()

    def run(name, arguments):
        env = os.environ.copy()
        for key, suffix in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
            directory = output/name/suffix
            directory.mkdir(parents=True)
            env[key] = str(directory)
        log = output/(name+'.log')
        env['NAOYA_QA_OUTPUT'] = str(output/name)
        if args.release in ['0.9.10','0.9.11','0.9.12','0.9.13','0.9.14','0.9.15','0.9.16','0.9.17','0.9.18','0.9.19','0.9.20','0.9.21','0.9.24']:
            env['NAOYA_QA_ARENA'] = 'punchline' if name == 'map_v0924_test' else 'legacy'
        command = [str(engine),'--headless','--path',str(project)]+arguments
        with log.open('w',encoding='utf-8') as stream:
            try:
                result = subprocess.run(command,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=180)
                exit_code = result.returncode
            except subprocess.TimeoutExpired:
                stream.write('\nQA TIMEOUT: 180 segundos; proceso terminado.\n')
                exit_code = 124
        contents = log.read_text(encoding='utf-8',errors='replace')
        results = re.findall(r'(?:RESULTADO|RESULT|DEMO RESULT)\s+(\d+)/(\d+)',contents)
        passed, total = map(int,results[-1]) if results else (0,0)
        status = exit_code == 0 and 'SCRIPT ERROR' not in contents
        if name != 'importacion':
            status = status and total > 0 and passed == total and 'ERROR:' not in contents and not re.search(r'^FAIL ',contents,re.M)
        return {'name':name,'exit_code':exit_code,'passed':passed,'total':total,'ok':status,
                'command':command,'log':log.name,'arena':env.get('NAOYA_QA_ARENA','project-default')}

    report = {'version':version,'automated':True,'rendering':'headless','results':[]}
    imported = run('importacion',['--editor','--import','--quit'])
    report['results'].append(imported)
    if imported['ok']:
        suites = ['combat_test','polish_test','presentation_test','assets_test','revision_test','video_feedback_test','hud_test','hud_feedback_test','modelo_alien_test','visual_revision_test','crystal_v095_test','integration_v095_test','ragdoll_v095_test','update_v096_test','update_v097_test','preferences_migration_v097_test']
        if args.release in ['0.9.8','0.9.9','0.9.10','0.9.11','0.9.12','0.9.13','0.9.14','0.9.15','0.9.16','0.9.17','0.9.18','0.9.19','0.9.20','0.9.21','0.9.24']: suites += ['update_v098_test','preferences_migration_v098_test']
        if args.release in ['0.9.9','0.9.10','0.9.11','0.9.12','0.9.13','0.9.14','0.9.15','0.9.16','0.9.17','0.9.18','0.9.19','0.9.20','0.9.21','0.9.24']: suites += ['robot_test_v099','robot_skills_v099_test','map_crystal_v099_test','preferences_migration_v099_test']
        if args.release in ['0.9.10','0.9.11','0.9.12','0.9.13','0.9.14','0.9.15','0.9.16','0.9.17','0.9.18','0.9.19','0.9.20','0.9.21','0.9.24']: suites += ['map_v0924_test']
        with ThreadPoolExecutor(max_workers=2) as pool:
            jobs = [pool.submit(run,name,['--script','res://qa/'+name+'.gd','--fixed-fps','60','--','--qa-controlled']) for name in suites]
            for job in jobs:
                result = job.result()
                report['results'].append(result)
                print(result['name'],f"{result['passed']}/{result['total']}",result['ok'],flush=True)
        report['results'].append(run('demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--revision']))
        report['results'].append(run('hud_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--hud']))
        report['results'].append(run('modelo_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--modelo']))
        report['results'].append(run('v094_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--v094']))
    if imported['ok']:
        report['results'].append(run('v095_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--v095']))
    if imported['ok']:
        report['results'].append(run('v096_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--v096']))
    if imported['ok']:
        report['results'].append(run('v097_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--v097']))
    if imported['ok'] and args.release in ['0.9.8','0.9.9','0.9.10','0.9.11','0.9.12','0.9.13','0.9.14','0.9.15','0.9.16','0.9.17','0.9.18','0.9.19','0.9.20','0.9.21','0.9.24']:
        report['results'].append(run('v098_demo',['--script','res://qa/review_demo.gd','--fixed-fps','60','--','--v098']))
    report['ok'] = all(result['ok'] for result in report['results'])
    (output/'resumen.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('RESUMEN',report['ok'],flush=True)
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
