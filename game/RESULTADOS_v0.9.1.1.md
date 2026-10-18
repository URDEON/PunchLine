# Resultados — Naoya 0.9.1.1

Motor ejecutado: `4.4.1.stable.official.49a5bc7b6`, Linux x86_64, ejecutable enviado por el usuario. No se descargó otro Godot. Los videos revisados son de 0.9.1 con **4.7.2**, confirmado por el usuario. No se ejecutó el parche en 4.7.2.

## Pruebas automatizadas sin imagen

| Suite | Aprobadas |
|---|---:|
| combat_test.gd | 37/37 |
| polish_test.gd | 25/25 |
| presentation_test.gd | 22/22 |
| assets_test.gd | 23/23 |
| revision_test.gd | 60/60 |
| video_feedback_test.gd | 60/60 |
| **Total de suites** | **227/227** |
| review_demo.gd --revision | **9/9** |

La misma demo también aprobó 9/9 con `--realtime`, para comprobar sus esperas a ritmo de segundos. Son los mismos nueve casos, no otras nueve comprobaciones distintas.

La suite nueva incluye 45 contactos reales sobre quietos a 1,2/1,8/2,2/4/8 m y −49°/−45°/−30°/−15°/0°/+15°/+30°/+45°/+49°. Comprueba preparación sin desplazamiento, giro limitado, contacto sobre blanco congelado lateral, cámara fija en compromiso, evasión final sin retención, rechazo fuera del cono, contacto evolucionado de 22, emisión de estelas en avance/órbita, ausencia de nuevas siluetas durante reposo, limpieza y efectos desactivados. Las suites anteriores comprueban paredes, M1, Counter, fases, menú y restantes reglas.

Las acciones de la demo son **automatizadas**. Se preparan posiciones/energía/HP de laboratorio de forma explícita, y luego se usan las funciones reales del juego. El caso añadido espera que termine la recuperación del Counter antes de pulsar 1; no modifica reglas para producir el resultado.

La primera ejecución de ese caso falló porque el guion pulsaba 1 durante la recuperación del Counter. Se corrigió únicamente la espera del guion y se repitió la demo. Se conserva el registro inicial como `demo_preparacion_antes.log`; `demo.log` y `demo_realtime.log` son las ejecuciones finales aprobadas.

Los resultados finales están en `qa/resultados_v0911/`. `resumen.json` recoge códigos de salida y comandos. El diagnóstico antes/después conserva 35 casos; no se suma como otras 35 pruebas distintas a la suite que ya incluye esos casos. El primer guion experimental no aislaba los cuerpos de todos los NPC y fue corregido antes de usar sus resultados como evidencia.

## Importación y captura

Importación incremental completada con código de salida 0, sin errores de parseo. El editor registra cuatro errores de apertura de listeners locales, relacionados con las restricciones del entorno; quedan en `importacion.log`. Las 23 comprobaciones de carga de recursos pasan. El ZIP no incluye la caché `.godot`: el editor de destino reimportará los originales.

Se volvió a ejecutar `qa/grabar_ffmpeg.py` sobre 0.9.1.1. Xorg no pudo abrir los listeners locales: `Cannot establish any listening sockets`. Se detuvo antes de ejecutar Godot con gráficos y antes de grabar con FFmpeg. **No se creó ningún MP4 nuevo.** La duración del video no es el impedimento. Los registros y procedencia están en `qa/resultados_v0911/captura/`.

El texto de NPC y la legibilidad de las estelas siguen pendientes de comprobar visualmente en el parche. Las pruebas sin imagen no certifican animación percibida, estética del HUD, rendimiento del renderer ni calidad de audio. `REVISION_DE_TUS_VIDEOS.md` distingue lo observado en tus grabaciones anteriores de lo probado tras corregir.

## Repetir

Desde la carpeta extraída, con Python 3 y el ejecutable indicado:

```sh
python3 qa/repetir_pruebas_v0911.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/resultados_nuevos
```

El script importa y ejecuta las seis suites y la demo. Usar una carpeta de resultados nueva; conserva cada comando y separa las preferencias de los casos.

Solo para la regresión del feedback:

```sh
/ruta/Godot_v4.4.1-stable_linux.x86_64 --headless --path . --script res://qa/video_feedback_test.gd --fixed-fps 60
```

Para grabar en un entorno con pantalla permitida:

```sh
python3 qa/grabar_ffmpeg.py --godot /ruta/Godot_v4.4.1-stable_linux.x86_64 --output /ruta/captura_naoya_0911
```

MP4 previsto: `Naoya_v0911_prueba.mp4`, H.264/yuv420p, 1280×720 y 30 FPS. Audio opcional desde una fuente PulseAudio real. Requiere revisión de fotogramas y registros después de grabarse; ver `GRABACION_REAL.md`.
