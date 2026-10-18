"""Pruebas locales reales de controladores, sin imagen ni conexión ENet."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess


def main(extra_suites=()):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        parser.error('Usar una carpeta nueva para conservar registros anteriores')
    output.mkdir(parents=True)
    results = []
    for suite in ['fusion_test', 'fusion_network_test', 'menu_revision_test', 'network/ui_test', 'network/full_local'] + list(extra_suites):
        name = suite.replace('/', '_')
        env = os.environ.copy()
        env.update({'XDG_DATA_HOME': str(output/name/'data'),
                    'XDG_CONFIG_HOME': str(output/name/'config'),
                    'XDG_CACHE_HOME': str(output/'cache'), 'NAOYA_NET_QA': '1'})
        for key in ['XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME']:
            Path(env[key]).mkdir(parents=True, exist_ok=True)
        command = [str(args.godot.resolve()), '--headless', '--max-fps', '60',
                   '--path', str(args.project.resolve()), '--script', f'res://qa/{suite}.gd']
        run = subprocess.run(command, env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True, timeout=180)
        (output/f'{name}.log').write_text(run.stdout)
        count = re.search(r'RESULTADO (\d+)/(\d+)', run.stdout)
        passed, total = map(int, count.groups()) if count else (0, 0)
        ok = run.returncode == 0 and total > 0 and passed == total and not re.search(r'(SCRIPT ERROR|^ERROR:|^FAIL )', run.stdout, re.M)
        result = dict(suite=suite, passed=passed, total=total, ok=ok, command=command)
        results.append(result)
        print(f'{suite}: {passed}/{total} {ok}', flush=True)
    report = dict(automated=True, rendering='headless', transport='local_controller_harness',
                  ok=all(r['ok'] for r in results), results=results)
    (output/'resumen.json').write_text(json.dumps(report, indent=2)+'\n')
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
