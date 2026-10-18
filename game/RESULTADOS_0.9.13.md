# Verificación 0.9.13

Acciones automatizadas con el Godot 4.4.1 Linux adjuntado, Compatibility/Jolt. La demo original se importó y arrancó antes de editarla; cargó sus 22 módulos. La copia 0.9.12 sigue separada como respaldo.

| Comprobación | Resultado | Alcance |
|---|---:|---|
| Regresión individual | 1205/1205 | Combate, HUD, rigs, robots, cristalización, mapa y demos anteriores |
| Fusión y controlador | 20/20 | Cuatro mechas, 22 piezas/texturas, señal única a 11,5 s, altura 4 m, bloqueos, colisión, reinicio, vibración dentro/fuera de 4 m y VFX por chasis |
| Fusión autoritativa y réplica local | 29/29 | Los cuatro chasis, reparto único, barrera eliminada, movimiento por entrada real, pasos, vidrio sin superposición y búsqueda de zona exterior bajo techo |
| Menú inicial | 30/30 | Home/Jugar/Controles en cinco tamaños, de 360×360 a 1920×1080, con foco de teclado |
| Nombre e interfaz online | 16/16 | Cinco tamaños, escritura real, espacios, Ñ, P y persistencia |
| Controladores online anteriores | 28/28 | Daño/contactos, counter, vidrio, formas, dominio, Kogane, emote, huesos, cooldowns y paquetes comprimidos de tres actores |

Son 1328 comprobaciones de lógica/recursos sin imagen. El harness de réplica ejecuta los controladores y la física reales en mundos locales; no conecta tres equipos mediante ENet.

## Exportación

El PCK final superó 20/20 pruebas de fusión, 29/29 de fusión/réplica y 28/28 de combate online local: 77/77, sin errores de carga ni GDScript.

Se genera EXE y PCK completos con plantillas 4.4.1 ya presentes. El paquete exportado vuelve a comprobarse mediante el runtime Linux: resultados en `resultados_v0913/native_*`. Eso verifica recursos empacados y comportamiento del mismo PCK; no equivale a ejecutar el EXE en Windows.

La primera comprobación del PCK detectó PNG extraídos de GLTF excluidos por error. Se corrigió el filtro para conservar esas dependencias, se reexportó y se repitió la comprobación. No se entrega aquel paquete incompleto.

## Límites de la evidencia

- Las texturas se comprueban como recursos cargados; la fidelidad visual y auditiva requiere revisión manual. No se afirma haber visto la cinemática renderizada en esta sesión.
- Xorg no consigue crear sus sockets: `Cannot establish any listening sockets`. El registro original está en `resultados_v0913/bloqueos/display.log`. No hay video ni captura nuevos; los MP4 recibidos son referencias de UI.
- Crear un socket ENet devuelve `ERR_CANT_CREATE (20)` en este entorno. No se intentó eludir la restricción. Las pruebas locales no certifican una conexión con latencia real.
- No hay prueba nativa Windows ni Godot 4.7.2. Se conserva el editor 4.4.1 suministrado; no se descargó otra versión.
- Rust Vanguard no tiene rig operativo ni locomoción articulada; no se presenta su traslación rígida como una animación de marcha.

## Repetir sin imagen

Desde la carpeta que contiene `project.godot`, utilizando una carpeta nueva de resultados:

```sh
PUNCHLINE_GODOT=/ruta/al/Godot_4.4.1
"$PUNCHLINE_GODOT" --headless --editor --path . --import
python qa/repetir_pruebas_v0913.py --godot "$PUNCHLINE_GODOT" --output /tmp/punchline_regresion_nueva
python qa/repetir_fusion_v0913.py --godot "$PUNCHLINE_GODOT" --output /tmp/punchline_fusion_nueva
python qa/network/repeat.py --godot "$PUNCHLINE_GODOT" --output /tmp/punchline_enet_nueva
```

El último comando requiere UDP permitido. El segundo runner configura `NAOYA_NET_QA=1` para que su réplica local reciba entradas del harness y no intente enviar paquetes al peer offline.

Con gráficos disponibles, ejecutar `FusionDemo.tscn` o abrir la demostración desde el menú. Godot permite una captura real en un equipo compatible:

```sh
"$PUNCHLINE_GODOT" --path . res://FusionDemo.tscn --resolution 1280x720 --fixed-fps 30 --write-movie /ruta/prueba_fusion.avi --quit-after 360
ffmpeg -i /ruta/prueba_fusion.avi -c:v libx264 -pix_fmt yuv420p -r 30 -c:a aac -movflags +faststart /ruta/prueba_fusion.mp4
```

Estos comandos de grabación se conservan para repetir; no se presentan como ejecutados con éxito aquí. `qa/fusion/PRUEBA_MANUAL.md` incluye interiores, cuatro chasis, controles y tres jugadores.
