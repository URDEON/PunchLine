# Captura real de Naoya 0.9.1.1

Actualización del parche: se repitió el intento y Xorg continúa bloqueado al abrir listeners locales. No hay MP4 de 0.9.1.1. Las seis suites aprueban 227/227 y la demo actualizada 9/9 sin imagen. El guion añade el 1 sobre un blanco cercano lateral después de un Counter real, esperando la recuperación. Ver `RESULTADOS_v0.9.1.1.md` y los registros nuevos en `qa/resultados_v0911/captura/`.

Los videos del usuario sí se revisaron: muestran 0.9.1 en Godot 4.7.2; la revisión de su señal de audio fue cuantitativa, sin escucha. No sirven como grabación de los cambios del parche. El historial de ejecución de 0.9.1 sigue más abajo.

## Resultado actual

Se usa exclusivamente el ejecutable entregado por el usuario, `Godot_v4.4.1-stable_linux.x86_64`, versión `4.4.1.stable.official.49a5bc7b6`. Es compatible con el contenedor. No se descargó otro motor. SHA-256 del ejecutable: `54215149d52efb1d653a3dec39d0993587bdf5daa2c56e787b5ee88417fb1339`.

La importación headless terminó. El editor registró errores de listeners locales y cuatro `Parameter "t" is null` al guardar escenas 3D con el renderer Dummy. No hay errores de parseo de GDScript y la carga de recursos aprueba 23/23. Esto no comprueba su aspecto gráfico.

Las cinco suites aprobaron 167/167, y la demo de esta revisión aprobó 8/8 sin imagen. No son una grabación ni una inspección de animación, HUD o audio.

El intento real con `qa/grabar_ffmpeg.py` terminó antes de iniciar Godot gráfico: Xorg no puede abrir listeners UNIX y reporta `Cannot establish any listening sockets`. Una comprobación `AF_UNIX bind` en carpeta escribible devuelve `errno=1, Operation not permitted`. La limitación es la conexión local que necesita la pantalla, no la duración del video ni el formato del ejecutable. Se preservan la procedencia y registros en `qa/resultados_v091/captura/`.

**No se generó un MP4 ni fotogramas de gameplay.** No hay audio grabado para revisar. Este contenedor tampoco tiene PulseAudio. Para revisar la presentación actual hacen falta capturas/video de una ejecución con gráficos.

## Repetir en Linux con pantalla permitida

Desde la carpeta extraída del proyecto, con el mismo Godot, Python 3, FFmpeg con x11grab/libx264 y Xorg con controlador dummy:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/captura_naoya_0911
```

Si hay una pantalla X11 ya disponible:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --existing-display --display :0 --output /ruta/captura_naoya_0911
```

El script importa, inicia la demo `qa/review_demo.gd --revision --realtime`, espera a que Godot y el grabador estén preparados, y captura la ventana real. MP4: `Naoya_v0911_prueba.mp4`, 1280×720, 30 FPS, H.264, yuv420p y faststart. La ruta gráfica completa sigue sin validarse aquí porque Xorg está bloqueado. El script no altera permisos del entorno ni descarga motores.

Con servidor PulseAudio y fuente monitor real, añadir `--pulse-source NOMBRE.monitor`; graba a AAC. Sin esa opción captura sin audio. No añade una pista de audio fabricada.

## Qué ejecuta la demostración

Acciones automatizadas sobre las mecánicas reales: autoapuntado lateral, evasión final con dash de NPC, variante cercana, Counter contra un ataque real y su liberación, combo M1, menú con cinco modos por NPC, muerte con energía completa que renace FORM1 y evolución desde FORM1. Los preparativos del laboratorio de salud/cargas/posiciones aparecen rotulados. No se modifica el daño o las colisiones para conseguir resultados.

La espera de Counter usa el reloj de física desde el estado activo, porque la detención empieza al recibir el ataque, no al pulsar 2. `--realtime` mantiene el ritmo de demostración en segundos. `--start-flag` sincroniza comienzo de acciones con FFmpeg. No alteran reglas del combate.

La fase 2D de representación del Counter está pendiente y se indica en pantalla. La demo conserva la representación actual; no simula un resultado visual terminado.

## Comandos de 0.9.1 usados anteriormente (historial)

```sh
XDG_CACHE_HOME=/workspace/.cache XDG_DATA_HOME=/workspace/qa_v091/import/data XDG_CONFIG_HOME=/workspace/qa_v091/import/config /workspace/godot_adjuntado/ejecutable/Godot_v4.4.1-stable_linux.x86_64 --headless --editor --path /workspace/naoya_v0_9_1 --import
python3 /workspace/naoya_v0_9_1/qa/grabar_ffmpeg.py --godot /workspace/godot_adjuntado/ejecutable/Godot_v4.4.1-stable_linux.x86_64 --project /workspace/naoya_v0_9_1 --output /workspace/deliverables/captura_v091 --skip-import
XDG_CACHE_HOME=/workspace/.cache XDG_DATA_HOME=/workspace/qa_v091/demo/data XDG_CONFIG_HOME=/workspace/qa_v091/demo/config /workspace/godot_adjuntado/ejecutable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /workspace/naoya_v0_9_1 --script res://qa/review_demo.gd --fixed-fps 60 -- --revision
XDG_CACHE_HOME=/workspace/.cache XDG_DATA_HOME=/workspace/qa_v091/demo_realtime/data XDG_CONFIG_HOME=/workspace/qa_v091/demo_realtime/config /workspace/godot_adjuntado/ejecutable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /workspace/naoya_v0_9_1 --script res://qa/review_demo.gd -- --revision --realtime
```

## Inspeccionar un MP4 cuando sea posible

```sh
ffprobe -v error -show_streams -show_format captura_naoya_0911/Naoya_v0911_prueba.mp4
mkdir -p fotogramas
ffmpeg -i captura_naoya_0911/Naoya_v0911_prueba.mp4 -vf 'fps=1/3' fotogramas/revision_%03d.png
ffmpeg -i captura_naoya_0911/Naoya_v0911_prueba.mp4 -vf 'blackdetect=d=0.2:pix_th=0.1' -an -f null -
```

Ver el video completo y las PNG por etapa: deben mostrar combate, órbita, dash, HUD, menú y fases sin imagen negra, personajes invisibles o errores. Si hay audio, escucharlo y comprobar su señal:

```sh
ffmpeg -i captura_naoya_0911/Naoya_v0911_prueba.mp4 -af volumedetect -vn -f null -
```

Existencia del MP4 o aprobación de tests sin imagen no sustituyen esa revisión.
