"""Run and clean up two actual ENet processes for the grass/fog integration."""
import os
import pathlib
import subprocess
import sys
import time

root = pathlib.Path(__file__).resolve().parents[2]
output = root / "housing/docs/evidence/greenery_v0927/network"
output.mkdir(parents=True, exist_ok=True)
command = ["/workspace/godot441/Godot_v4.4.1-stable_linux.x86_64", "--headless",
           "--path", str(root), "--script", "housing/qa/greenery_network_run.gd", "--"]
env = dict(os.environ, XDG_CONFIG_HOME="/workspace/.config",
           XDG_DATA_HOME="/workspace/.local/share", XDG_CACHE_HOME="/workspace/.cache")
processes = []
try:
    for role in ["host", "client"]:
        log = (output / f"{role}.txt").open("w")
        processes.append((subprocess.Popen(command + [f"--housing-{role}"], env=env,
                                           stdout=log, stderr=subprocess.STDOUT), log))
        if role == "host":
            time.sleep(1)
    codes = [process.wait(timeout=220) for process, _ in processes]
    print("Greenery ENet process exits:", codes)
    sys.exit(0 if codes == [0, 0] else 1)
finally:
    for process, log in processes:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=10)
        log.close()
