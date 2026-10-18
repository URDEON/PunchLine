#!/usr/bin/env python3
"""Captura la pantalla real de Godot con FFmpeg. No descarga motores ni simula imágenes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time


def stop(process):
    if process is not None and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, type=Path)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, default=Path('captura_naoya'))
    parser.add_argument('--display', default=':97')
    parser.add_argument('--existing-display', action='store_true')
    parser.add_argument('--skip-import', action='store_true')
    parser.add_argument('--short', action='store_true')
    parser.add_argument('--pulse-source', help='Fuente real de PulseAudio, por ejemplo naoya.monitor')
    args = parser.parse_args()
    engine, project, output = args.godot.resolve(), args.project.resolve(), args.output.resolve()
    if not engine.is_file():
        parser.error('No se encuentra el ejecutable adjuntado')
    if not shutil.which('ffmpeg'):
        parser.error('FFmpeg no está instalado')
    output.mkdir(parents=True, exist_ok=True)
    movie = output/'Naoya_v097_prueba_real.mp4'
    if movie.exists():
        parser.error('El MP4 ya existe; elige otra carpeta para conservarlo')
    env = os.environ.copy()
    env.update({'DISPLAY': args.display, 'LIBGL_ALWAYS_SOFTWARE': '1'})
    for name, directory in [('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config')]:
        env[name] = str(output/directory)
        (output/directory).mkdir(exist_ok=True)
    version = subprocess.check_output([str(engine), '--version'], env=env, text=True).strip()
    print('GODOT_ADJUNTADO', version, flush=True)
    metadata = {'engine': str(engine), 'version': version,
                'engine_sha256': hashlib.sha256(engine.read_bytes()).hexdigest(),
                'project': str(project), 'capture': 'FFmpeg x11grab, 1280x720, 30 FPS',
                'automated_actions': True, 'audio_source': args.pulse_source,
                'status': 'preparando'}
    provenance = output/'procedencia_captura.json'
    provenance.write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    if not args.skip_import:
        with (output/'importacion.log').open('w') as log:
            result = subprocess.run([str(engine), '--headless', '--editor', '--path', str(project), '--import', '--quit'],
                                    env=env, stdout=log, stderr=subprocess.STDOUT, timeout=180)
        if result.returncode:
            raise RuntimeError('Falló la importación; revisar importacion.log')
    display = game = recorder = None
    logs = []
    try:
        if not args.existing_display:
            if not shutil.which('Xorg'):
                raise RuntimeError('No está instalado Xorg con el controlador dummy')
            Path('/tmp/.X11-unix').mkdir(exist_ok=True)
            display_log = (output/'pantalla_virtual_salida.log').open('w')
            logs.append(display_log)
            display = subprocess.Popen(['Xorg', args.display, '-config', str(Path(__file__).with_name('pantalla_virtual.conf')),
                                        '-logfile', str(output/'pantalla_virtual.log'), '-nolisten', 'tcp', '-noreset', '-ac'],
                                       env=env, stdout=display_log, stderr=subprocess.STDOUT)
            socket_path = Path('/tmp/.X11-unix')/('X'+args.display.lstrip(':').split('.')[0])
            deadline = time.monotonic()+10
            while not socket_path.exists():
                if display.poll() is not None:
                    raise RuntimeError('La pantalla virtual no pudo abrir sus conexiones locales; revisar pantalla_virtual.log')
                if time.monotonic()>deadline:
                    raise RuntimeError('La pantalla virtual no respondió en 10 segundos')
                time.sleep(0.1)
        ready, flag = output/'demo_ready', output/'empezar_demo'
        ready.unlink(missing_ok=True)
        flag.unlink(missing_ok=True)
        game_log = (output/'godot_grafico.log').open('w')
        logs.append(game_log)
        command = [str(engine), '--path', str(project), '--script', 'res://qa/review_demo.gd',
                   '--display-driver', 'x11', '--rendering-method', 'gl_compatibility',
                   '--resolution', '1280x720', '--position', '0,0', '--borderless', '--max-fps', '60',
                   '--audio-driver', 'PulseAudio' if args.pulse_source else 'Dummy',
                   '--', '--realtime', '--output='+str(output), '--start-flag='+str(flag)]
        if args.short:
            command.append('--short')
        else:
            command.append('--v097')
        game = subprocess.Popen(command, env=env, stdout=game_log, stderr=subprocess.STDOUT)
        deadline = time.monotonic()+60
        while not ready.exists():
            if game.poll() is not None:
                raise RuntimeError('Godot no inició la demo gráfica; revisar godot_grafico.log')
            if time.monotonic()>deadline:
                raise RuntimeError('Godot no preparó la demo en 60 segundos')
            time.sleep(0.1)
        capture = ['ffmpeg', '-hide_banner', '-n', '-f', 'x11grab', '-framerate', '30', '-video_size', '1280x720',
                   '-i', args.display+'.0+0,0']
        if args.pulse_source:
            capture += ['-f', 'pulse', '-i', args.pulse_source]
        capture += ['-c:v', 'libx264', '-preset', 'fast', '-crf', '20', '-pix_fmt', 'yuv420p', '-r', '30']
        capture += ['-c:a', 'aac', '-b:a', '128k'] if args.pulse_source else ['-an']
        capture += ['-movflags', '+faststart', str(movie)]
        ffmpeg_log = (output/'ffmpeg.log').open('w')
        logs.append(ffmpeg_log)
        recorder = subprocess.Popen(capture, env=env, stdin=subprocess.PIPE, stdout=ffmpeg_log, stderr=subprocess.STDOUT)
        time.sleep(0.5)
        if recorder.poll() is not None:
            raise RuntimeError('FFmpeg no pudo capturar la pantalla; revisar ffmpeg.log')
        flag.write_text('iniciar acciones automatizadas\n', encoding='utf-8')
        print('CAPTURA_REAL_INICIADA', flush=True)
        deadline = time.monotonic()+180
        while game.poll() is None:
            if recorder.poll() is not None:
                raise RuntimeError('FFmpeg terminó antes de completar la demo')
            if time.monotonic()>deadline:
                raise RuntimeError('La demo superó el límite de 180 segundos')
            time.sleep(0.2)
        recorder.communicate(input=b'q\n', timeout=20)
        if game.returncode or recorder.returncode:
            raise RuntimeError('La ejecución o la captura terminó con errores; revisar ambos registros')
        game_contents = (output/'godot_grafico.log').read_text()
        if 'ERROR:' in game_contents or 'FAIL ' in game_contents:
            raise RuntimeError('La demo contiene errores o comprobaciones fallidas; el MP4 requiere revisión')
        metadata['status'] = 'grabado; pendiente de inspección visual y de audio'
        probe = json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(movie)],text=True))
        duration = float(probe['format']['duration'])
        metadata['duration'] = duration
        metadata['audio_present'] = any(s['codec_type']=='audio' for s in probe['streams'])
        metadata['frames_to_review'] = []
        for label, second in [('inicio',min(1.0,duration*.1)),('medio',duration*.5),('final',max(0.0,duration-1))]:
            frame = output/('fotograma_'+label+'.png')
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-n','-ss',str(second),'-i',str(movie),'-frames:v','1',str(frame)],check=True)
            metadata['frames_to_review'].append(frame.name)
        print('MP4_REAL_GENERADO', movie, flush=True)
    except Exception as error:
        metadata['status'] = 'bloqueado o fallido'
        metadata['error'] = str(error)
        print('CAPTURA_NO_COMPLETADA:', error, flush=True)
        return 1
    finally:
        stop(recorder)
        stop(game)
        stop(display)
        for log in logs:
            log.close()
        provenance.write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding='utf-8')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
