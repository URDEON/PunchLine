# Verificación — PunchLine 0.9.14

Editor utilizado: **Godot 4.4.1 adjuntado por el usuario**, Compatibility/Jolt. No se descargó otro editor. Acciones automatizadas.

| Prueba | Resultado | Alcance |
|---|---:|---|
| Regresión anterior | 1205/1205 | Combate, rigs/ragdolls base, vidrio, mapa, HUD y habilidades |
| Fusión | 20/20 | Cuatro chasis, 22 piezas/texturas, 11,5 s, altura, bloqueo y reinicio |
| Fusión y réplica local | 29/29 | Cuatro variantes, montaje, movimiento por entrada, pasos, vidrio y techo |
| Menú inicial | 30/30 | Cinco tamaños y foco de teclado |
| Formulario online | 16/16 | Escritura real, espacios/Ñ/P, persistencia y cinco tamaños |
| Controladores online locales | 28/28 | Contactos/daño, formas, counter, vidrio, dominio y snapshots |
| Correcciones de mechas | 44/44 | Energía válida/bloqueada/fallida por chasis, carga al reaparecer, rig, orientación, poses, estadísticas, M1 a 3,7 m, guardia y restauración |
| HUD holográfico | 16/16 | Cuatro habilidades y menú dentro de cinco tamaños; energía conservada y cambio a Naoya |
| ENet real, tres procesos | 20/20 | Conexión, carga inicial, Ultimate, guardia, G, 22 piezas, 300 HP, gait, audio, detención y vibración por distancia |

Son **1388 comprobaciones locales**, más **20 por ENet real**. La conexión real se hizo por localhost, no entre tres PC por Internet.

## Paquete Windows

Se generó el EXE con las plantillas 4.4.1 ya presentes. El PCK exportado se ejecutó mediante el runtime Linux 4.4.1: 44/44 de mechas, 29/29 de fusión/réplica y 16/16 de HUD, **89/89**. Esto comprueba los recursos del paquete destinado a Windows; no equivale a ejecutar el EXE en Windows.

Los tests detienen las voces y dan tiempo al mezclador de audio antes de cerrar. Los primeros cierres acelerados de QA dejaban avisos de AudioStreamPlayback pendientes; los registros de validación usan la limpieza corregida.

## Imagen, video y sonido

Godot arrancó con X11 y OpenGL/Mesa llvmpipe al concederse el acceso adicional del entorno. Hay capturas reales del HUD, vuelo, activación, apoyo, M1 y configuración. `mecha_shader_probe.gd` comprobó los shaders y las texturas después de compactar recursos.

`Mechas_0.9.14.mp4` es una grabación real del motor con acciones automatizadas: **1280×720, 30 FPS, H.264 y AAC estéreo 48 kHz, 16,73 s**. Se revisaron fotogramas y no se detectaron tramos negros. El audio tiene señal y su pico queda por debajo de 0 dBFS.

La grabación corresponde a la revisión visual de esta actualización. Después se afinó el apoyo de la suela y se compactaron recursos sin cambiar geometría ni píxeles. No es una prueba manual ni un benchmark: renderizar por software en Movie Maker fue mucho más lento que tiempo real.

## Límites pendientes

- Windows nativo, Godot 4.7.2 y FPS en hardware del usuario.
- Latencia real entre PC/VPN, pérdida de paquetes y recorrido completo por desniveles.
- Evaluación auditiva final con altavoces/auriculares. El entorno grabó la mezcla del motor sin dispositivo ALSA físico.
- La ruta GPU de partículas en Forward+ no se certificó; el render comprobado usa Compatibility y partículas CPU.
- Las piezas mantienen sus cortes originales. El rig mecánico es articulado, sin retopología o pesos orgánicos; los especiales 1–4 siguen pendientes.

## Repetir

Desde la carpeta con `project.godot`, indicando el Godot disponible y directorios nuevos:

```sh
PUNCHLINE_GODOT=/ruta/al/Godot_4.4.1
"$PUNCHLINE_GODOT" --headless --editor --path . --import
python qa/repetir_pruebas_v0914.py --godot "$PUNCHLINE_GODOT" --output /tmp/punchline_regresion_nueva
python qa/repetir_mechas_v0914.py --godot "$PUNCHLINE_GODOT" --output /tmp/punchline_mechas_nuevo
python qa/network/repeat.py --godot "$PUNCHLINE_GODOT" --scenario mechas --output /tmp/punchline_enet_nuevo --port 17918
```

Para repetir la grabación en un entorno con gráficos:

```sh
"$PUNCHLINE_GODOT" --path . --resolution 1280x720 --fixed-fps 30 --write-movie /ruta/prueba_mechas.avi --script res://qa/mecha_visual_review.gd
ffmpeg -i /ruta/prueba_mechas.avi -c:v libx264 -crf 22 -pix_fmt yuv420p -r 30 -c:a aac -movflags +faststart /ruta/prueba_mechas.mp4
```

Las capturas se guardan en `user://mecha_visual_review` o en `NAOYA_QA_OUTPUT`. Los registros y manifiestos están en `resultados_v0914`; el compactador audita la igualdad de geometría, animaciones y píxeles en `assets/fusion/mechas_compartidos/verificacion.json`.
