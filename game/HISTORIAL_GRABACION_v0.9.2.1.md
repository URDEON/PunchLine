# Captura real de Naoya 0.9.2.1

Motor del usuario: Godot `4.4.1.stable.official.49a5bc7b6`, Linux x86_64. No se descargó otro motor. SHA-256: `54215149d52efb1d653a3dec39d0993587bdf5daa2c56e787b5ee88417fb1339`.

El intento de esta versión falló antes de iniciar Godot gráfico: Xorg no puede abrir listeners locales y devuelve `Cannot establish any listening sockets`. Los diagnósticos anteriores de AF_UNIX bind devolvieron `errno=1, Operation not permitted`. La duración de la grabación no es el impedimento. No se generó un MP4. Registros en `qa/resultados_v0921/captura/`.

Se conservan los comandos, el script FFmpeg y la demo. Las pruebas sin imagen aprobaron 398 comprobaciones, demo de combate 9/9 y demo del HUD 10/10. Los valores y posiciones iniciales de laboratorio son explícitos; después se activan las funciones reales. Las acciones son automatizadas.

## Grabar con pantalla permitida

Desde la carpeta extraída, con Python3, FFmpeg (x11grab/libx264), Xorg y su controlador dummy:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/captura_naoya_0921
```

Con una pantalla X11 existente:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --existing-display --display :0 --output /ruta/captura_naoya_0921
```

El script importa, ejecuta `qa/review_demo.gd --hud --realtime`, espera la señal de Godot y sincroniza las acciones con el inicio de FFmpeg. Exporta `Naoya_v0921_prueba.mp4`: 1280×720, 30 FPS, H.264/yuv420p y faststart. Añadir `--pulse-source NOMBRE.monitor` solo si existe esa fuente real de PulseAudio; entonces graba AAC. Sin fuente captura sin audio. No agrega sonido fabricado.

La demo muestra HUD al 80%, salud73/energía62 preparadas explícitamente en laboratorio, Counter contra un ataque real, lista bajo el retrato con Naoya y dos Coming Soon, clic automatizado en el triángulo, reloj detenido, Pruebas/Ajustes/Controles, reducción al 50% y las fichas de Fase1/Fase2. No cambia mecánicas para producir resultados. La representación plana del Counter en el mundo sigue pendiente; el dibujo del HUD no la sustituye.

## Revisión obligatoria después de grabar

```sh
ffprobe -v error -show_streams -show_format /ruta/captura_naoya_0921/Naoya_v0921_prueba.mp4
mkdir -p /ruta/fotogramas
ffmpeg -i /ruta/captura_naoya_0921/Naoya_v0921_prueba.mp4 -vf 'fps=1/3' /ruta/fotogramas/revision_%03d.png
ffmpeg -i /ruta/captura_naoya_0921/Naoya_v0921_prueba.mp4 -vf 'blackdetect=d=0.2:pix_th=0.1' -an -f null -
ffmpeg -i /ruta/captura_naoya_0921/Naoya_v0921_prueba.mp4 -af volumedetect -vn -f null -
```

Ver los fotogramas y el video: ventana y HUD completos, menú visible, modelos presentes y ninguna pantalla negra. Revisar logs por errores. Si hay audio, escucharlo además de medir su señal. Un archivo creado o una suite sin imagen no sustituye esa comprobación.

Las imágenes de `qa/vistas_hud/` son vistas vectoriales de diseño, no capturas del juego. Se exportaron del modelo de dibujo real con `qa/exportar_hud.gd` y se rasterizaron con librsvg/Cairo. No certifican contraste sobre el mapa ni tipografía exacta del renderer. El historial anterior se conserva en `HISTORIAL_GRABACION_v0.9.1.1.md`.
