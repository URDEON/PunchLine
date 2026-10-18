# Pruebas PunchLine 0.9.19

## Proyecto editable

- Regresión general: **1205/1205** comprobaciones.
- Integración de controladores, combate, HUD, cámara y réplicas: **359/359**.
- Total: **1564/1564** comprobaciones locales automatizadas.

La integración incluye 84 comprobaciones específicas de cuerpo/mirada/gestos y 12 de su réplica online; también se mantienen 34 de apoyos y 9 de réplicas de locomoción.

Se comprobaron los cuatro emotes de cada robot base: aceptación, clip original avanzando y cambios reales en las poses óseas del baile. Sentinel ejecuta sus cuatro gestos procedurales, mantiene los apoyos y recupera locomoción o combate al cancelarlos.

Primera persona: cabeza excluida de la cámara local, pecho/pelvis/brazos/piernas/pies/juntas visibles por sus capas, restauración de cabeza en tercera persona, posición de ojos delante del pecho y límites del cuello. Se revisaron además poses técnicas exportadas desde Godot en Blender; no son capturas ni video de gameplay.

## Mediciones

- Error máximo del pie plantado en el recorrido de suelo, pendientes, escalones y plataforma: **0,00785 m**, frente a 0,0423 m en la prueba 0.9.18.
- Máximo incluyendo pies en vuelo: **0,0865 m**. La solución limita el alcance en vez de estirar las piernas; no se afirma precisión perfecta en el vuelo.
- En desplazamiento lateral, el rango de balanceo del brazo alrededor de Z fue **0,257–0,264 rad**, frente a **0,0093 rad** en avance. Los destinos de paso siguen la dirección recorrida y los tobillos no se cruzan en los casos comprobados.
- Las longitudes de segmentos conservan error inferior a 0,002 m en la prueba. Máximo de **dos consultas de suelo por actualización del planificador**; las réplicas realizan cero.
- Tres snapshots completos siguen dentro de los 64 KiB antes de compresión. Se transmiten dos apoyos, una dirección de vista y el índice/reloj de emote; no las 112 transformaciones de las piezas.
- Sonda aislada sin imagen: medianas **0,117–0,128 ms** de CPU con la marcha activada. No es una medición de FPS ni de GPU.
- No se añadieron modelos, texturas o nuevos esqueletos físicos. Se conserva la agrupación de geometría y las juntas compartidas anteriores.

## Paquete exportado

**144/144 comprobaciones aprobadas sobre el PCK exportado.** Se comprueba el PCK destinado a Windows con Godot Linux, cargando sus recursos reales y ejecutando las pruebas externas de cuerpo/emotes, réplicas y combate. Sus resultados y comandos quedan en `resultados_v0919/exportacion.json` y los registros `exportado_*`. Esto no equivale a haber ejecutado el EXE nativamente en Windows.

## Límites de la comprobación

Motor ejecutado: Godot **4.4.1 Linux** proporcionado por el usuario. No hay pantalla X11/Wayland accesible para revisar una partida gráfica. La importación y exportación del editor reportan que no pueden abrir sus puertos TCP locales en el sandbox; la exportación del PCK y las pruebas de controladores sí se completan.

Pendientes: calidad visual definitiva, oclusiones en poses extremas, FPS/GPU en Windows/Godot 4.7.2 y partida WAN entre PC reales. No se generó video simulado. Las réplicas comprobadas usan dos mundos locales y los controladores reales.

## Repetir

```sh
python qa/repetir_pruebas_v0919.py --godot /ruta/Godot --output /ruta/nueva/regresion
python qa/repetir_mechas_v0919.py --godot /ruta/Godot --output /ruta/nueva/integracion
python qa/verificar_exportacion_v0919.py --godot /ruta/Godot --pack /ruta/PunchLine_0.9.19.pck --output /ruta/nueva/exportacion
```
