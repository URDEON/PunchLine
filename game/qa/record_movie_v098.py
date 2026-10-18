#!/usr/bin/env python3
"""Ejecuta Godot real en X11; Movie Maker graba imagen y audio, FFmpeg exporta MP4."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',type=Path,required=True)
    parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--probe',action='store_true')
    parser.add_argument('--crystal-probe',action='store_true')
    parser.add_argument('--display',default=':98')
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists(): parser.error('Usar una carpeta de salida nueva')
    output.mkdir(parents=True)
    project = args.project.resolve()
    env = os.environ.copy()
    env.update(DISPLAY=args.display,LIBGL_ALWAYS_SOFTWARE='1',NAOYA_QA_OUTPUT=str(output))
    for key,folder in [('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config')]:
        target = output/folder;target.mkdir();env[key]=str(target)
    Path('/tmp/.X11-unix').mkdir(exist_ok=True)
    display_log = (output/'xorg_stdout.log').open('w')
    display = subprocess.Popen(['Xorg',args.display,'-config',str(project/'qa/pantalla_virtual.conf'),'-logfile',str(output/'Xorg.log'),'-nolisten','tcp','-noreset','-ac'],env=env,stdout=display_log,stderr=subprocess.STDOUT)
    report = {'real_godot':True,'automated_actions':True,'capture':'Godot Movie Maker / MJPEG + PCM, convertido por FFmpeg','commands':[],'ok':False}
    try:
        socket = Path('/tmp/.X11-unix')/('X'+args.display.lstrip(':').split('.')[0])
        deadline = time.monotonic()+10
        while not socket.exists():
            if display.poll() is not None: raise RuntimeError('Xorg terminó; revisar Xorg.log')
            if time.monotonic()>deadline: raise RuntimeError('Xorg no creó la pantalla en 10 segundos')
            time.sleep(.1)
        print('PANTALLA_REAL_DISPONIBLE',flush=True)
        probe = args.probe or args.crystal_probe
        script = 'res://qa/crystal_graphics_v098.gd' if args.crystal_probe else ('res://qa/render_probe_v098.gd' if args.probe else 'res://qa/review_demo.gd')
        command = [str(args.godot.resolve()),'--path',str(project),'--script',script,'--display-driver','x11','--rendering-method','gl_compatibility','--resolution','1280x720','--audio-driver','Dummy']
        if not probe:command += ['--fixed-fps','30','--write-movie',str(output/'prueba.avi'),'--','--v098','--demo-fps=30','--output='+str(output)]
        else:command += ['--fixed-fps','30']
        report['commands'].append(command)
        with (output/'godot.log').open('w') as log:
            game = subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=1500)
        report['game_exit'] = game.returncode
        contents = (output/'godot.log').read_text(errors='replace')
        if game.returncode or 'SCRIPT ERROR' in contents or 'ERROR:' in contents or 'FAIL ' in contents:raise RuntimeError('Godot terminó con errores; revisar godot.log')
        if not probe:
            video = output/'Naoya_v0.9.8_prueba_real.mp4'
            command = ['ffmpeg','-v','error','-n','-i',str(output/'prueba.avi'),'-r','30','-c:v','libx264','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(video)]
            report['commands'].append(command);subprocess.run(command,check=True)
            report['media']=json.loads(subprocess.check_output(['ffprobe','-v','quiet','-show_streams','-show_format','-of','json',str(video)]))
            duration = float(report['media']['format']['duration'])
            for index,second in enumerate([1,duration*.25,duration*.5,duration*.75,duration-1]):
                subprocess.run(['ffmpeg','-v','error','-ss',str(second),'-i',str(video),'-frames:v','1',str(output/f'frame_{index}.png')],check=True)
            print('MP4_REAL',video,flush=True)
        report['ok']=True
    except Exception as exc:
        report['error']=str(exc);print('CAPTURA_FALLIDA',str(exc),flush=True)
    finally:
        display.terminate()
        try:display.wait(timeout=5)
        except subprocess.TimeoutExpired:display.kill();display.wait()
        display_log.close()
        (output/'procedencia.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    return 0 if report['ok'] else 1


if __name__ == '__main__':raise SystemExit(main())
