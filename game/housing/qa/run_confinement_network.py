"""Exercise real ENet replication of house clearance and procedural hand contacts."""
import os
import pathlib
import subprocess
import sys
import time
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--suite', choices=['confinement', 'multistorey'], default='confinement')
suite = parser.parse_args().suite

root = pathlib.Path(__file__).resolve().parents[2]
output = root / f'housing/docs/evidence/{suite}/network'
output.mkdir(parents=True, exist_ok=True)
command = ['/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64', '--headless',
           '--path', str(root), '--script', f'housing/qa/{suite}_network_run.gd', '--']
env = dict(os.environ, XDG_CONFIG_HOME='/workspace/.config',
           XDG_DATA_HOME='/workspace/.local/share', XDG_CACHE_HOME='/workspace/.cache')
processes = []
try:
    for role in ['host', 'client']:
        log = (output / f'{role}.txt').open('w')
        processes.append((subprocess.Popen(command + [f'--housing-{role}'], env=env,
                                           stdout=log, stderr=subprocess.STDOUT), log))
        if role == 'host':
            time.sleep(1)
    codes = [process.wait(timeout=115) for process, _ in processes]
    print('Confinement ENet process exits:', codes)
    sys.exit(0 if codes == [0, 0] else 1)
finally:
    for process, log in processes:
        if process.poll() is None:
            process.terminate()
        log.close()
