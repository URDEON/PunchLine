# Prueba gráfica y grabación real de Naoya 0.9.4

Se usó exclusivamente el Godot 4.4.1 adjuntado: `4.4.1.stable.official.49a5bc7b6`, Linux x86_64. No se descargó otro motor. El usuario usa 4.7.2; esa versión no se ejecutó aquí.

La pantalla virtual está bloqueada: Xorg devuelve `failed to bind listener` y `Cannot establish any listening sockets`. El impedimento son las conexiones locales, no la duración del video. Registros en `qa/resultados_v094/pantalla/`. No hay MP4 de esta entrega ni animación que simule gameplay.

## Ver la demo real

Desde la carpeta del proyecto, con escritorio gráfico:

```sh
/ruta/Godot --path . --script res://qa/review_demo.gd --resolution 1280x720 -- --v094 --realtime
```

En PowerShell, usando tu ejecutable Windows:

```powershell
& 'C:\ruta\Godot.exe' --path . --script res://qa/review_demo.gd --resolution 1280x720 -- --v094 --realtime
```

Las acciones son automatizadas. Muestra guardia caminando, combo con hook nuevo, patada, counter ante ataque real y liberación después de cinco segundos, Kogane, fase 2 vertical/horizontal y dominio con su final normal. Prepara dummies y energía de forma explícita en los subtítulos; no modifica daño, cooldowns ni invulnerabilidad. Dura aproximadamente un minuto.

Para comprobar la captura 2D con gráficos:

```sh
/ruta/Godot --path . --script res://qa/visual_revision_test.gd --fixed-fps 60
```

La prueba gráfica verifica píxeles visibles y fondo transparente de la textura y guarda `qa/captura_pose_v094.png`. Inspeccionar también el juego desde ambos lados del vidrio: una textura correcta por sí sola no demuestra toda la composición.

## Grabar con FFmpeg en Linux X11

Con Python 3, FFmpeg y una pantalla X11 existente:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot --existing-display --display :0 --output /ruta/captura_naoya_094
```

Para un entorno que permita pantalla virtual y tenga Xorg con controlador dummy:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot --output /ruta/captura_naoya_094
```

El script importa, espera a Godot y sincroniza las acciones con FFmpeg. Genera `Naoya_v094_prueba_real.mp4`: 1280×720, 30 FPS, H.264, yuv420p y faststart. Guarda registros y procedencia. Añadir `--pulse-source NOMBRE.monitor` con una fuente real de PulseAudio para audio AAC. Sin fuente se graba sin audio. El script usa X11; en Windows puedes grabar la misma demo con tu capturador de escritorio.

## Revisar el archivo

```sh
ffprobe -v error -show_streams -show_format /ruta/captura_naoya_094/Naoya_v094_prueba_real.mp4
mkdir -p /ruta/fotogramas
ffmpeg -i /ruta/captura_naoya_094/Naoya_v094_prueba_real.mp4 -vf 'fps=1/3' /ruta/fotogramas/revision_%03d.png
ffmpeg -i /ruta/captura_naoya_094/Naoya_v094_prueba_real.mp4 -vf 'blackdetect=d=0.2:pix_th=0.1' -an -f null -
```

Inspeccionar fotogramas, video y registros: modelo, HUD y efectos completos; ausencia de pantallas negras, errores y deformaciones. Escuchar el audio si se incluyó. La marca «grabado» del script requiere esta revisión visual. Las pruebas sin imagen no la sustituyen.
